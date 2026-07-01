// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:sakenph/classes/nominatim_response.dart';
import 'package:sakenph/globals/enums.dart';

/// Saves details that are heavily required by search logic.
class SearchDetailsProvider extends ChangeNotifier {
  List<NominatimPlace> _fromLocSearchResults = [];
  List<NominatimPlace> _toLocSearchResults = [];

  // For logic to be able to edit the contents of the textfields
  final TextEditingController _fromLocTextController = TextEditingController();
  final TextEditingController _toLocTextController = TextEditingController();
  final FocusNode _toLocFocusNode = FocusNode(); //

  // Used to show/hide the widget set that holds the search result depending if the user is
  // currently using the textfields.
  bool _isActiveSearching_fromLoc = false;
  bool _isActiveSearching_toLoc = false;

  // /////////////////////////////////////////////////////////////////////////////////////////////
  // Getters
  // /////////////////////////////////////////////////////////////////////////////////////////////

  bool get isActiveSearching_fromLoc => _isActiveSearching_fromLoc;
  bool get isActiveSearching_toLoc => _isActiveSearching_toLoc;

  List<NominatimPlace> get getFromLocSearchResults => _fromLocSearchResults;
  List<NominatimPlace> get getToLocSearchResults => _toLocSearchResults;
  TextEditingController get getFromLocTextController => _fromLocTextController;
  TextEditingController get getToLocTextController => _toLocTextController;
  FocusNode get getToLocFocusNode => _toLocFocusNode;

  // /////////////////////////////////////////////////////////////////////////////////////////////
  // Setters
  // /////////////////////////////////////////////////////////////////////////////////////////////

  set setFromLocTextfieldText(String value) {
    _fromLocTextController.text = value;
  }

  set setToLocTextfieldText(String value) {
    _toLocTextController.text = value;
  }

  /// Will only notify listeners if provided a different value from the existing value
  set setActiveSearching_fromLoc(bool value) {
    print("FROM: $value");
    if (_isActiveSearching_fromLoc == value) return;
    _isActiveSearching_fromLoc = value;
    notifyListeners();
  }

  /// Will only notify listeners if provided a different value from the existing value
  set setActiveSearching_toLoc(bool value) {
    if (_isActiveSearching_toLoc == value) return;
    _isActiveSearching_toLoc = value;
    notifyListeners();
  }

  // /////////////////////////////////////////////////////////////////////////////////////////////
  // Functions
  // /////////////////////////////////////////////////////////////////////////////////////////////

  /// Tries to clear search results if the user attempts to type more again
  void tryToEraseLocResults(SearchFieldType type) {
    switch (type) {
      case SearchFieldType.from:
        if (_fromLocSearchResults.isEmpty) return;
        _fromLocSearchResults.clear();
        notifyListeners();
      case SearchFieldType.to:
        if (_toLocSearchResults.isEmpty) return;
        _toLocSearchResults.clear();
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
        _fromLocSearchResults = resultList;
        notifyListeners();
      case SearchFieldType.to:
        _toLocSearchResults = resultList;
        notifyListeners();
    }
  }

  void requestFocusTowardsLocTextfield() {
    _toLocFocusNode.requestFocus();
  }

  void unfocusFromLocTextfield() {
    _toLocFocusNode.unfocus();
  }
}

  /// When the user is selecting the ToLocation, the FromLocation is assumed to be
  /// filled in already.
  ///
  /// After selecting the ToLocation, the lat lon of the two locations are obtained,
  /// ready for computing the shortest path
  ///
  /*
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
  }*/

  // TODO: REWORK THIS METHOD. COMPACTING EVERYTHING IN ONE PLACE SEEMS RLLY STUPID
  /*
  void _setToLocationDetails_andStartCalculating(
    double lat,
    double lon,
    String name,
    BuildContext buildContext,
  ) async {
    //wipeSuggestedShortestPaths();

    SystemVariablesProvider systemVariablesProvider = buildContext
        .read<SystemVariablesProvider>();
    SearchDetailsProvider searchDetailsProvider = buildContext
        .read<SearchDetailsProvider>();
    MapHelperProvider mapHelperProvider = buildContext
        .read<MapHelperProvider>();

    toLocController.text = name;
    //_selectedToLocationDetails = LatLng(lat, lon);
    notifyListeners();
    await Future.delayed(
      Duration(milliseconds: 200),
    ); // Give time to let the user see that the ToLocation textfield was changed

    toLocFocusNode.unfocus();
    systemVariablesProvider.setAppCurrentState(
      SystemState.waitingForBackendResponse,
    );

    searchDetailsProvider.saveSuggestedShortestPaths(
      await queryForShortestPath(
        _selectedFromLocationDetails!,
        _selectedToLocationDetails!,
      ),
    );
    systemVariablesProvider.setAppCurrentState(SystemState.showSuggestedRoutes);
  }
  */

