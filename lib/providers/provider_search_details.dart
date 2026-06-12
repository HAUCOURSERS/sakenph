import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/classes/nominatim_response.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

class SearchDetailsProvider extends ChangeNotifier {
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

  /// Originally obtained in a json format. Paths may contain more than one shortest paths.
  // 
  // Sample output in json:
  /*
    {
      "routes": {
        "result-1": [
          {
            "mode": {
              "type": "walk",
              "details": {
                "name": "On foot",
                "color": "#005eff"
              }
            },
            "geometry": [
              [120.5872876, 15.1345705],
              [120.5873933, 15.1345113],
              [120.5874381, 15.1345798],
              [120.5875794, 15.1348006],
              [120.5881366, 15.1344614],
              [120.5881806, 15.1344335],
              [120.5884364, 15.1342726],
              [120.5886514, 15.134151],
              [120.5888889, 15.1340141],
              [120.5892275, 15.1338121],
              [120.5895063, 15.1336655],
              [120.5897269, 15.1336267],
              [120.5900492, 15.1336987],
              [120.5902923, 15.1337569],
              [120.5905847, 15.133291],
              [120.5905788, 15.133211],
              [120.5898783, 15.1325823],
              [120.5899615, 15.1324832]
            ]
          }
        ]
      }
    }
  */
  Map<String, dynamic>? _suggestedShortestPaths;

  // /////////////////////////////////////////////////////////////////////////////////////////////
  // Getters
  // /////////////////////////////////////////////////////////////////////////////////////////////

  bool get isFromLocationDetailsEmpty => _selectedFromLocationDetails != null;
  bool get isToLocationDetailsEmpty => _selectedToLocationDetails != null;

  bool get isFromLocTextfieldEmpty => _isFromLocTextfieldEmpty;
  bool get isToLocTextfieldEmpty => _isToLocTextfieldEmpty;

  Map<String, dynamic>? get suggestedShortestPaths => _suggestedShortestPaths;

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
    _selectedFromLocationDetails = LatLng(lat, lon);
    toLocFocusNode.requestFocus();
    notifyListeners();
  }

  /// When the user is selecting the ToLocation, the FromLocation is assumed to be
  /// filled in already.
  ///
  /// After selecting the ToLocation, the lat lon of the two locations are obtained,
  /// ready for computing the shortest path
  void setToLocationDetails(
    NominatimPlace nomiDetails,
    BuildContext buildContext,
  ) {
    _setToLocationDetails(
      nomiDetails.lat,
      nomiDetails.lon,
      nomiDetails.name,
      buildContext,
    );
  }

  void _setToLocationDetails(
    double lat,
    double lon,
    String name,
    BuildContext buildContext,
  ) async {
    toLocController.text = name;
    _selectedToLocationDetails = LatLng(lat,lon);
    //print("From Location Details: " + _selectedFromLocationDetails.toString());
    //print("To Location Details: " + _selectedToLocationDetails.toString());
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 200));
    toLocFocusNode.unfocus();
    if (buildContext.mounted) {
      buildContext.read<SystemVariablesProvider>().setAppCurrentState(
        SystemState.waitingForBackendResponse,
      );
      buildContext.read<SystemVariablesProvider>().mapWidgetController.shortestPath(_selectedFromLocationDetails!, _selectedToLocationDetails!);
      buildContext.read<SystemVariablesProvider>().setAppCurrentState(SystemState.hideWidgets);
    }
  }

  /// To save the computed shortest paths to the provider for later use
  void saveSuggestedShortestPaths(Map<String, dynamic>? val) {
    _suggestedShortestPaths = val;
    notifyListeners();
  }
}
