import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sakenph/map_widget.dart';

/// Storing origin and destination LatLng values and anything relevant to the MapWidget
class MapWidgetHandlerProvider with ChangeNotifier {
  /// A controller class that can be used to gain access to the MapWidget widget state that's rendered
  /// in the home page widget and be able to run its methods.
  MapWidgetController mapWidgetController = MapWidgetController();
}
