import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sakenph/classes/nominatim_response.dart';

import 'package:sakenph/map_widget.dart';

/// Provider that's useful for handling information dedicated to the Maplibre map.
/// Saves values/details that are needed to perform map operations
class MapHelperProvider extends ChangeNotifier {
  /// This will be passed as an argument value when creating the MapWidget widget and during the MapWidget's
  /// initialization, this will be fed with its state pointer, finally allowing this to share pointer details
  /// across the app and use its methods.
  MapWidgetController mapWidgetController = MapWidgetController();

  double _userCompassRotation = 0;
  LatLng _userCurrentGeoLoc = LatLng(0, 0); // 0,0 for now.

  LatLng? _selectedFromLocationDetails;
  LatLng? _selectedToLocationDetails;

  /// Originally obtained in a json format. Paths may contain more than one shortest paths.
  Map<String, dynamic> _suggestedShortestPaths = {};

  // /////////////////////////////////////////////////////////////////////////////////////////////
  // Getters
  // /////////////////////////////////////////////////////////////////////////////////////////////

  bool get getIsFromLocationDetailsEmpty =>
      _selectedFromLocationDetails != null;
  bool get getIsToLocationDetailsEmpty => _selectedToLocationDetails != null;

  LatLng? get getSelectedFromLocationDetails => _selectedFromLocationDetails;
  LatLng? get getSelectedToLocationDetails => _selectedToLocationDetails;
  double get getUserCompassRotation => _userCompassRotation;
  LatLng get getUserCurrentGeoLoc => _userCurrentGeoLoc;

  /// Uses Geolocator library to get user current position and extracts the lat lon values for later use
  Future<void> get getUserCurrentLocAndSaveToContext async {
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.best),
    );
    _userCurrentGeoLoc = LatLng(position.latitude, position.longitude);
  }

  /// Data is inserted usually by functions in backend_service.dart
  Map<String, dynamic> get getSuggestedShortestPaths => _suggestedShortestPaths;
  bool get getIsSuggestedShortestPathsEmpty => _suggestedShortestPaths.isEmpty;

  /// When someone searches for shortest routes, the backend may return more than one.
  /// When displaying data, you'd wanna just get one of the routes.
  ///
  /// Valid route id format => "result-(number)"
  /// Ex: result-1, result-2, result-3
  Map<String, dynamic> getFilteredRouteByID(String routeId) {
    final routes = Map<String, dynamic>.from(
      _suggestedShortestPaths['routes'] as Map<String, dynamic>,
    );
    routes.removeWhere((key, value) => key != routeId);
    return {'routes': routes};
  }

  // /////////////////////////////////////////////////////////////////////////////////////////////
  // Setters
  // /////////////////////////////////////////////////////////////////////////////////////////////

  /// Mainly used by the compass_direction_listener.dart
  set setUserCompassRotation(double rotation) {
    _userCompassRotation = rotation;
  }

  /// Takes in a [NominatimPlace] object and only takes the latitude, longitude
  /// and name details
  set setFromLocationDetails(NominatimPlace nomiDetails) {
    _setFromLocationDetails(nomiDetails.lat, nomiDetails.lon);
  }

  set setToLocationDetails(NominatimPlace nomiDetails) {
    _setToLocationDetails_withLatLng(nomiDetails.lat, nomiDetails.lon);
  }

  /// To save the computed shortest paths to the provider for later use
  set setSuggestedShortestPaths(Map<String, dynamic> val) {
    _suggestedShortestPaths = val;
    //print("[TEMP] Saved suggested shortest paths");
    notifyListeners();
  }

  set setUserCurrentGeoLoc(LatLng latlng) {
    _userCurrentGeoLoc = latlng;
  }

  void fetchUserCurrentGeolocationAndSave() async {
    Position position = await GeolocatorPlatform.instance.getCurrentPosition();
    _userCurrentGeoLoc = LatLng(position.latitude, position.longitude);
  }

  // ignore: non_constant_identifier_names
  void _setToLocationDetails_withLatLng(double lat, double lon) {
    _selectedToLocationDetails = LatLng(lat, lon);
    notifyListeners();
  }

  /// The main <code>setFromLocationDetails</code> method. Only the <code>lat, lon, name</code>
  /// details are needed to perform app logic.
  ///
  /// FromLocation will be used alongside ToLocation to compute optimal route.
  void _setFromLocationDetails(double lat, double lon) {
    _selectedFromLocationDetails = LatLng(lat, lon);
    notifyListeners();
  }

  // /////////////////////////////////////////////////////////////////////////////////////////////
  // Internals
  // /////////////////////////////////////////////////////////////////////////////////////////////

  /// Normally when you try to get the user's current location, there's a slight delay.
  /// To solve that issue, the user's current location is immediately obtained upon app startup,
  /// so when you try to use your current location as your 'from' coordinates, you don't
  /// have to wait extra time waiting.
  void useCurrentUserGeoLocAsOrigin(BuildContext context) {
    _setFromLocationDetails(
      _userCurrentGeoLoc.latitude,
      _userCurrentGeoLoc.longitude,
    );
  }

  void clearSuggestedShortestPaths() {
    //print("[TEMP] SUGGESTED SHORTEST PATHS CLEARED");
    _suggestedShortestPaths.clear();
    notifyListeners();
  }
}
