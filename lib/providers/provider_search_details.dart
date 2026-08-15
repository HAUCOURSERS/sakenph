// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sakenph/classes/nominatim_response.dart';
import 'package:sakenph/globals/enums.dart';

/// Saves details that are heavily required by search logic.
class SearchDetailsProvider extends ChangeNotifier {
  List<NominatimPlace> _fromLocSearchResults = [];
  List<NominatimPlace> _toLocSearchResults = [];

  // For logic to be able to edit the contents of the textfields
  final TextEditingController _fromLocTextController = TextEditingController();
  final TextEditingController _toLocTextController = TextEditingController();
  final FocusNode _fromLocFocusNode = FocusNode();
  final FocusNode _toLocFocusNode = FocusNode(); //

  // Obtained from interactive where you long-press the map
  LatLng _longPressedLocation = LatLng(0, 0);

  // Used to show/hide the widget set that holds the search result depending if the user is
  // currently using the textfields.
  bool _isActiveSearching_fromLoc = false;
  bool _isActiveSearching_toLoc = false;

  /// If true, it will grab the current geoloc value upon route computation.
  ///
  /// This had to be implemented due to an edge case where somehow when the user
  /// starts the app, they immediately press the "Press to use your location" so fast
  /// that the geoloc function at the start isn't done fetching yet, causing weird
  /// route results.
  bool _isUsingCurrentGeoLoc = false;

  /// Default: false; Because it doesn't automatically fail upon app startup. Only goes true if a search fails.
  // These bool values get turned back to false if the textfield is changed by the user or by hitting retry.
  bool _isNominatimSearchFailed_TypeFrom = false; // fromloc textfield
  bool _isNominatimSearchFailed_TypeTo = false; // toloc textfield
  // This bool value gets turned back to false if the search is tried again by either selecting the ToLocation loc or hitting retry
  bool _isBackendRouteFetchFailed = false;

  // /////////////////////////////////////////////////////////////////////////////////////////////
  // Getters
  // /////////////////////////////////////////////////////////////////////////////////////////////

  bool get isActiveSearching_fromLoc => _isActiveSearching_fromLoc;
  bool get isActiveSearching_toLoc => _isActiveSearching_toLoc;

  bool get isNominatimSearchFailed_TypeFrom =>
      _isNominatimSearchFailed_TypeFrom;
  bool get isNominatimSearchFailed_TypeTo => _isNominatimSearchFailed_TypeTo;
  bool get isBackendRouteFetchFailed => _isBackendRouteFetchFailed;

  bool get isUsingCurrentGeoLoc => _isUsingCurrentGeoLoc;

  LatLng get getLongPressedLocation => _longPressedLocation;

  List<NominatimPlace> get getFromLocSearchResults => _fromLocSearchResults;
  List<NominatimPlace> get getToLocSearchResults => _toLocSearchResults;
  TextEditingController get getFromLocTextController => _fromLocTextController;
  TextEditingController get getToLocTextController => _toLocTextController;

  FocusNode get getFromLocFocusNode => _fromLocFocusNode;
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

  set setIsUsingCurrentGeoLoc(bool value) {
    _isUsingCurrentGeoLoc = value;
  }

  set setIsNominatimSearchFailed_TypeFrom(bool value) {
    _isNominatimSearchFailed_TypeFrom = value;
    notifyListeners();
  }

  set setIsNominatimSearchFailed_TypeTo(bool value) {
    _isNominatimSearchFailed_TypeTo = value;
  }

  set setIsBackendRouteFetchFailed(bool value) {
    _isBackendRouteFetchFailed = value;
  }

  set setLongPressedLocation(LatLng coordinates) {
    _longPressedLocation = coordinates;
  }

  /// Will only notify listeners if provided a different value from the existing value
  set setActiveSearching_fromLoc(bool value) {
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
