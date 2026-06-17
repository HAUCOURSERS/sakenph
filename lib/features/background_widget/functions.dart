import 'package:maplibre_gl/maplibre_gl.dart';

/// Uses the geometry of a route, remake it into a List<LatLng> so the flyToBounds
/// method can be used for proper zooming.
List<LatLng> compileCoordsIntoLatLngList(
  Map<String, dynamic> path,
  String route_id,
) {
  List<LatLng> geometryList = [];
  for (final entry in path["routes"][route_id]) {
    List<LatLng> geometryToAppend = (entry["geometry"] as List<dynamic>).map((
      item,
    ) {
      final coords = (item as List<dynamic>)
          .map((coord) => (coord as num).toDouble())
          .toList();
      return LatLng(coords[1], coords[0]); // [lng, lat] → LatLng(lat, lng)
    }).toList();

    geometryList.addAll(geometryToAppend);
  }
  return geometryList;
}
