import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:sakenph/globals/variables.dart' as global_vars;

/// Attempts to get json results by submitting origin and destination [LatLng] values.
/// Returns a nullable <code>Map&lt;String, dynamic&gt;</code> value.
Future<Map<String, dynamic>?> queryForShortestPath(LatLng origin, LatLng dest) async {
  // TODO: Remove this print statement once done checking if the function is working as intended
  print("[TEMP] shortestPath() Method Called!");
  String localIp = global_vars.localIP;
  // Position gpsLocation = await determinePosition();

  print(
    'http://$localIp:8000/k_shortest_paths?src=${origin.latitude},${origin.longitude}&dest=${dest.latitude},${dest.longitude}',
  );
  final response = await http.get(
    Uri.parse(
      'http://$localIp:8000/k_shortest_paths?src=${origin.latitude},${origin.longitude}&dest=${dest.latitude},${dest.longitude}',
    ),
  );

  if (response.statusCode == 200) {
    print("[TEMP] Recieved backend response");
    final Map<String, dynamic> json = jsonDecode(response.body);
    return json;
  } else return null;
}