import 'package:flutter/material.dart';
import 'package:sakenph/classes/nominatim_response.dart';
import 'package:sakenph/globals/enums.dart';

/// Saves details that are heavily required by search logic.
class SearchDetailsProvider extends ChangeNotifier {
  List<NominatimPlace> _fromLocSearchResults = [];
  List<NominatimPlace> _toLocSearchResults = [];

  /// For logic to be able to edit the contents of the textfields
  final TextEditingController _fromLocTextController = TextEditingController();
  final TextEditingController _toLocTextController = TextEditingController();
  final FocusNode _toLocFocusNode = FocusNode(); //

  // /////////////////////////////////////////////////////////////////////////////////////////////
  // Getters
  // /////////////////////////////////////////////////////////////////////////////////////////////

  bool get isFromLocTextfieldEmpty => _fromLocTextController.text.isEmpty;
  bool get isToLocTextfieldEmpty => _toLocTextController.text.isEmpty;

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

  // /////////////////////////////////////////////////////////////////////////////////////////////
  // Functions
  // /////////////////////////////////////////////////////////////////////////////////////////////

  /// Used to help the background widget to decide whether to display the widget that holds
  /// the loading icon and the results ListView
  /// TODO: REVIEW CODE. THIS METHOD IS SUBJECT FOR REMOVAL IF REDUNDANT
  void setTextfieldEmptyStatus(bool val, SearchFieldType type) {
    return;
    /*
    switch (type) {
      case SearchFieldType.from:
        if (_isFromLocTextfieldEmpty == val) return;
        _isFromLocTextfieldEmpty = val;
        notifyListeners();
        break;
      case SearchFieldType.to:
        if (_isToLocTextfieldEmpty == val) return;
        _isToLocTextfieldEmpty = val;
        notifyListeners();
        break;
    }
    */
  }

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

