// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:sakenph/globals/variables.dart' as global_vars;

/// Attempts to get json results by submitting origin and destination [LatLng] values.
/// Returns a nullable <code>Map&lt;String, dynamic&gt;</code> value.
Future<Map<String, dynamic>> queryForShortestPath(
  LatLng origin,
  LatLng dest,
) async {
  final startTime = DateTime.now();
  String localIp = global_vars.localIP;
  // Position gpsLocation = await determinePosition();

  //print(
  //'https://sakenph-backend.onrender.com/k_shortest_paths?src=${origin.latitude},${origin.longitude}&dest=${dest.latitude},${dest.longitude}',
  //);
  final response = await http.get(
    Uri.parse(
      // render backend service link
      'https://sakenph-backend.onrender.com/k_shortest_paths?src=${origin.latitude},${origin.longitude}&dest=${dest.latitude},${dest.longitude}',

      // local backend
      //'http://$localIp:8000/k_shortest_paths?src=${origin.latitude},${origin.longitude}&dest=${dest.latitude},${dest.longitude}',
    ),
  );

  if (response.statusCode == 200) {
    print("[TEMP] Recieved backend response");
    final endTime = DateTime.now();
    print(endTime.difference(startTime).inMilliseconds);
    final Map<String, dynamic> json = jsonDecode(response.body);
    //print(json['routes']['result-1'][0]['geometry'].toString());

    //printLongString(json.toString());

    return json;
  } else {
    print("[TEMP] [WARNING] REQUEST FAIL!");
    return {};
  }
}
