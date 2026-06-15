import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sakenph/api/backend_service.dart';

LatLng getMiddleGeometryOfPath(Map<String, dynamic> path) {
  printLongString("ANALYZE THIS ==============> " + path.toString());

  // for now
  return LatLng(120.5969211, 15.1554372);
}
