import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'dart:math';

/// Provider that's useful for handling information dedicated to the Maplibre map.
class MapHelperProvider extends ChangeNotifier {
  // Will beu sing -90 -180 values to signify "null"
  LatLng _position1 = LatLng(-90, -180);
  LatLng _position2 = LatLng(-90, -180);

  /// Vital for knowing your previous positions to be able to tell the direction of where you're going
  void shiftPosition(LatLng pos) {
    _position2 = _position1;
    _position1 = pos;
  }

  double getMovementDirectionFromYourPositionHistory() {
    // There's definitely no way you're getting longitude of -180 while inside the philippines
    if (_position2.longitude == -180) return 0;

    // Once two points are established, imagine the
    final double lat1 = _position1.latitude * pi / 180;
    final double lat2 = _position2.latitude * pi / 180;
    final double dLng =
        (_position2.longitude - _position1.longitude) * pi / 180;

    final double y = sin(dLng) * cos(lat2);
    final double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);

    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  /// To reset them back to their "null" values if needed
  void resetPosValues() {
    _position1 = LatLng(-90, -180);
    _position2 = LatLng(-90, -180);
  }
}
