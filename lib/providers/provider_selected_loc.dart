import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Storing target lat long
class LatLongProvider with ChangeNotifier {
  LatLng? _toLoc;
  LatLng? get toLoc => _toLoc;

  void setToLoc(double lat, double lon) {
    _toLoc = LatLng(lat, lon);
    notifyListeners();
  }
}
