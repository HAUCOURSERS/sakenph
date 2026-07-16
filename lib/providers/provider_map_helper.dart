import 'dart:math';

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

  LatLng _userCurrentGeoLoc = LatLng(0, 0); // 0,0 for now.

  /// Used for saving the user's historical coordinates. This is used to calculate the user's heading/rotation.
  /// The last accepted coordinate is used to compare with the new coordinate to see if the new coordinate is
  /// far enough to be accepted. If the new coordinate is within 0.5 meters of the last accepted coordinate, it will be rejected.
  /// This is to prevent the user's heading from being jittery and unstable.
  List<LatLng> _userLatLngHistory = [];
  LatLng? _lastAcceptedLatLng;

  LatLng? _selectedFromLocationDetails;
  LatLng? _selectedToLocationDetails;

  /// Originally obtained in a json format. Paths may contain more than one shortest paths.
  Map<String, dynamic> _suggestedShortestPaths = {};

  /// Used to stop the app from making source and layers in the app if logic demands it
  bool _stopDrawing = false;

  // /////////////////////////////////////////////////////////////////////////////////////////////
  // Getters
  // /////////////////////////////////////////////////////////////////////////////////////////////

  bool get getIsFromLocationDetailsEmpty =>
      _selectedFromLocationDetails != null;
  bool get getIsToLocationDetailsEmpty => _selectedToLocationDetails != null;

  LatLng? get getSelectedFromLocationDetails => _selectedFromLocationDetails;
  LatLng? get getSelectedToLocationDetails => _selectedToLocationDetails;
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

  bool get shouldStopDrawing => _stopDrawing;

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
    notifyListeners();
  }

  set setStopDrawing(bool value) {
    _stopDrawing = value;
  }

  Future<void> fetchUserCurrentGeolocationAndSave() async {
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
  Future<void> useCurrentUserGeoLocAsOrigin() async {
    if (_userCurrentGeoLoc.latitude == 0 && _userCurrentGeoLoc.longitude == 0) {
      await getUserCurrentLocAndSaveToContext;
    }

    _setFromLocationDetails(
      _userCurrentGeoLoc.latitude,
      _userCurrentGeoLoc.longitude,
    );
  }

  void clearSuggestedShortestPaths() {
    _suggestedShortestPaths.clear();
    notifyListeners();
  }

  void saveLatLngForRotationComputation(LatLng newPoint) {
    if (_lastAcceptedLatLng == null) {
      _lastAcceptedLatLng = newPoint;
      _userLatLngHistory.add(newPoint);
      notifyListeners();
    }

    _lastAcceptedLatLng = newPoint;
    _userLatLngHistory.add(newPoint);
    notifyListeners();
  }

  /// Returns a compass heading in degrees based on two historical coordinates.
  /// The result is normalized to the range [0, 360).
  double getRotationFromLatLngHistory() {
    if (_userLatLngHistory.length < 2) {
      return 0.0; // Not enough data to calculate rotation
    }

    LatLng from = _userLatLngHistory[_userLatLngHistory.length - 2];
    LatLng to = _userLatLngHistory[_userLatLngHistory.length - 1];
    final double deltaLng = to.longitude - from.longitude;
    final double deltaLat = to.latitude - from.latitude;

    final double heading =
        (180 / 3.141592653589793) * (atan2(deltaLng, deltaLat));

    /// The heading value provided usually ranges from -180 to 180 degrees, so we normalize it to the range [0, 360) by adding 360 and taking the modulo.
    /// During testing, it was observed that the heading value was off by 180 degrees, so we add 180 degrees to correct it.
    return (heading + 360 + 180) % 360;
  }
}
