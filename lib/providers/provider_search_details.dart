import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/api/backend_service.dart';
import 'package:sakenph/classes/nominatim_response.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

import '../map_widget.dart';

class SearchDetailsProvider extends ChangeNotifier {
  MapWidgetController mapWidgetController = MapWidgetController();
  bool isLoading = false;
  List<NominatimPlace> fromLocResults = [];
  List<NominatimPlace> toLocResults = [];
  bool _isFromLocTextfieldEmpty = true; // Textfield is empty on default
  bool _isToLocTextfieldEmpty = true;

  /// For logic to be able to edit the contents of the textfields
  TextEditingController fromLocController = TextEditingController();
  TextEditingController toLocController = TextEditingController();

  FocusNode toLocFocusNode = FocusNode();

  LatLng? _selectedFromLocationDetails;
  LatLng? _selectedToLocationDetails;

  /// This value will be refreshed every 10 seconds.
  /// To why it has to be obtained in interval is to prevent the odd experience
  /// of waiting a few seconds to get user's loc
  LatLng _userCurrentGeoLoc = LatLng(0, 0); // 0,0 for now.

  /// Originally obtained in a json format. Paths may contain more than one shortest paths.
  Map<String, dynamic> _suggestedShortestPaths = {};

  // /////////////////////////////////////////////////////////////////////////////////////////////
  // Getters
  // /////////////////////////////////////////////////////////////////////////////////////////////

  bool get isFromLocationDetailsEmpty => _selectedFromLocationDetails != null;

  bool get isToLocationDetailsEmpty => _selectedToLocationDetails != null;

  bool get isFromLocTextfieldEmpty => _isFromLocTextfieldEmpty;

  bool get isToLocTextfieldEmpty => _isToLocTextfieldEmpty;

  LatLng? get selectedFromLocationDetails => _selectedFromLocationDetails;

  LatLng? get selectedToLocationDetails => _selectedToLocationDetails;

  // =============================================================================

  LatLng get getUserCurrentGeoLoc => _userCurrentGeoLoc;

  /// Data is inserted usually by functions in backend_service.dart
  Map<String, dynamic> get suggestedShortestPaths => _suggestedShortestPaths;

  // /////////////////////////////////////////////////////////////////////////////////////////////
  // Functions
  // /////////////////////////////////////////////////////////////////////////////////////////////

  /// Used to help the background widget to decide whether to display the widget that holds
  /// the loading icon and the results ListView
  void setTextfieldEmptyStatus(bool val, SearchFieldType type) {
    switch (type) {
      case SearchFieldType.from:
        if (isFromLocTextfieldEmpty == val) return;
        _isFromLocTextfieldEmpty = val;
        notifyListeners();
        break;
      case SearchFieldType.to:
        if (isToLocTextfieldEmpty == val) return;
        _isToLocTextfieldEmpty = val;
        notifyListeners();
        break;
    }
  }

  /// Tries to clear search results if the user attempts to type more again
  void tryToEraseLocResults(SearchFieldType type) {
    switch (type) {
      case SearchFieldType.from:
        if (fromLocResults.isEmpty) return;
        fromLocResults.clear();
        notifyListeners();
      case SearchFieldType.to:
        if (toLocResults.isEmpty) return;
        toLocResults.clear();
        notifyListeners();
    }
  }

  /// Saves the search results done in the FromLocation/ToLocation TextField. Once the results are saved
  /// in the provider variable, the background widget would listen for changes in the variable value
  /// and then start building the search result widgets.
  void saveLocSearchResults(
    List<NominatimPlace> resultList,
    SearchFieldType type,
  ) {
    switch (type) {
      case SearchFieldType.from:
        fromLocResults = resultList;
        notifyListeners();
      case SearchFieldType.to:
        toLocResults = resultList;
        notifyListeners();
    }
  }

  /// TODO: DEPRECATED. SUBJECT FOR REMOVAL<br/>
  /// Compact function that is solely for the button that suggests to use your current location.
  ///
  /// BuildContext pointer is required to properly transition to the ToLocation UI because
  /// fetching the user's current location is async and changing the widget state should only
  /// happen after it's done saving current user location details.
  ///
  /// Debouncer had to be used as this button may be prone to multiple presses in a short delay
  void setFromLocationDetails_usingCurrentLocation(
    BuildContext contextPointer,
  ) async {
    return;
    EasyDebounce.debounce(
      DebounceId.getCurrentLocation.toString(),
      Duration(milliseconds: 100),
      () async {
        await Future.delayed(Duration(milliseconds: 50));

        Position position = await Geolocator.getCurrentPosition();

        _setFromLocationDetails(
          position.latitude,
          position.longitude,
          "Your Current Location",
        );
        if (contextPointer.mounted) {
          contextPointer.read<SystemVariablesProvider>().setAppCurrentState(
            SystemState.gatheringToLoc,
          );
        }
      },
    );
  }

  /// Uses Geolocator library to get user current position and extracts the lat lon values for later use
  void getUserCurrentLocAndSaveToContext(BuildContext context) async {
    Position position = await Geolocator.getCurrentPosition();
    _userCurrentGeoLoc = LatLng(position.latitude, position.longitude);
  }

  void useCurrentUserGeoLocAsOrigin(BuildContext context) {
    _setFromLocationDetails(
      _userCurrentGeoLoc.latitude,
      _userCurrentGeoLoc.longitude,
      "Your Current Location",
    );
  }

  /// Takes in a [NominatimPlace] object and only takes the latitude, longitude
  /// and name details
  void setFromLocationDetails(NominatimPlace nomiDetails) {
    _setFromLocationDetails(nomiDetails.lat, nomiDetails.lon, nomiDetails.name);
  }

  /// The main <code>setFromLocationDetails</code> method. Only the <code>lat, lon, name</code>
  /// details are needed to perform app logic.
  ///
  /// FromLocation will be used alongside ToLocation to compute optimal route.
  void _setFromLocationDetails(double lat, double lon, String name) {
    fromLocController.text = name;
    setTextfieldEmptyStatus(false, SearchFieldType.from);
    _selectedFromLocationDetails = LatLng(lat, lon);
    toLocFocusNode.requestFocus();
    notifyListeners();
  }

  /// When the user is selecting the ToLocation, the FromLocation is assumed to be
  /// filled in already.
  ///
  /// After selecting the ToLocation, the lat lon of the two locations are obtained,
  /// ready for computing the shortest path
  void setToLocationDetails_andStartCalculating(
    NominatimPlace nomiDetails,
    BuildContext buildContext,
  ) {
    _setToLocationDetails_andStartCalculating(
      nomiDetails.lat,
      nomiDetails.lon,
      nomiDetails.name,
      buildContext,
    );
  }

  void _setToLocationDetails_andStartCalculating(
    double lat,
    double lon,
    String name,
    BuildContext buildContext,
  ) async {
    wipeSuggestedShortestPaths();

    toLocController.text = name;
    _selectedToLocationDetails = LatLng(lat, lon);
    notifyListeners();
    await Future.delayed(
      Duration(milliseconds: 200),
    ); // Give time to let the user see that the ToLocation textfield was changed

    toLocFocusNode.unfocus();
    if (buildContext.mounted) {
      buildContext.read<SystemVariablesProvider>().setAppCurrentState(
        SystemState.waitingForBackendResponse,
      );

      buildContext.read<SearchDetailsProvider>().saveSuggestedShortestPaths(
        await queryForShortestPath(
          _selectedFromLocationDetails!,
          _selectedToLocationDetails!,
        ),
      );
    }
  }

  ///
  void wipeSuggestedShortestPaths() {
    print("[TEMP] SUGGESTED SHORTEST PATHS CLEARED");
    _suggestedShortestPaths.clear();
    notifyListeners();
  }

  /// To save the computed shortest paths to the provider for later use
  void saveSuggestedShortestPaths(Map<String, dynamic> val) {
    _suggestedShortestPaths = val;
    print("[TEMP] Saved suggested shortest paths");
    notifyListeners();
  }

  /// When someone searches for shortest routes, the backend may return more than one.
  /// When displaying data, you'd wanna just get one of the routes.
  ///
  /// Valid route id format => "result-<number>"
  /// Ex: result-1, result-2, result-3
  Map<String, dynamic> getRouteByID(String route_id) {
    final routes = Map<String, dynamic>.from(
      _suggestedShortestPaths['routes'] as Map<String, dynamic>,
    );
    routes.removeWhere((key, value) => key != route_id);
    return {'routes': routes};
  }
}
