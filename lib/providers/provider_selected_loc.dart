import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Storing target lat long
class LatLongProvider with ChangeNotifier {
  LatLng? _fromLoc;
  LatLng? get fromLoc => _fromLoc;

  LatLng? _toLoc;
  LatLng? get toLoc => _toLoc;

  void setFromLoc(double lat, double lon) {
    _fromLoc = LatLng(lat, lon);
    notifyListeners();
  }

  void setToLoc(double lat, double lon) {
    _toLoc = LatLng(lat, lon);
    notifyListeners();
  }
}
