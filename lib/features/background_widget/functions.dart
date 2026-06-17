import 'package:maplibre_gl/maplibre_gl.dart';

LatLng getMiddleGeometryOfPath(Map<String, dynamic> path, String route_id) {
  List<List<double>> geometryList = [];
  /*
  for (final entry in path["routes"][route_id]) {
    List<List<double>> geometryToAppend = (entry["geometry"] as List<dynamic>)
        .map((item) => (item as List<dynamic>)
            .map((coord) => (coord as num).toDouble())
            .toList())
        .toList();
    
    geometryList.addAll(geometryToAppend);
  }
  */
  for (final entry in path["routes"][route_id]) {
    List<dynamic> geometryEntry = entry["geometry"];
    for (final latlng_dynamic in geometryEntry) {
      List<double> latlng = latlng_dynamic as List<double>;
      print(latlng.toString());
    }
  }

  return LatLng(120.5969211, 15.1554372);
}
