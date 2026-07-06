// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/globals/enums.dart';

import 'package:sakenph/globals/variables.dart' as global_vars;
import 'package:sakenph/providers/provider_system_vars.dart';

/// Attempts to get json results by submitting origin and destination [LatLng] values.
/// Returns a nullable <code>Map&lt;String, dynamic&gt;</code> value. BuildContext is passed
/// to allow for context.read() calls to be used in this function.
Future<Map<String, dynamic>> queryForShortestPath(
  LatLng origin,
  LatLng dest,
  BuildContext context,
) async {
  SystemVariablesProvider systemVariablesProvider = context
      .read<SystemVariablesProvider>();

  try {
    final startTime = DateTime.now();
    String localIp = global_vars.localIP;
    // Position gpsLocation = await determinePosition();

    //print(
    //'https://sakenph-backend.onrender.com/k_shortest_paths?src=${origin.latitude},${origin.longitude}&dest=${dest.latitude},${dest.longitude}',
    //);
    final response = await http.get(
      Uri.parse(
        // render backend service link
        //'https://sakenph-backend.onrender.com/k_shortest_paths?src=${origin.latitude},${origin.longitude}&dest=${dest.latitude},${dest.longitude}',

        // local backend
        //'http://$localIp:8000/k_shortest_paths?src=${origin.latitude},${origin.longitude}&dest=${dest.latitude},${dest.longitude}',

        // AWS EC2
        'http://ec2-47-129-217-58.ap-southeast-1.compute.amazonaws.com:8000/k_shortest_paths?src=${origin.latitude},${origin.longitude}&dest=${dest.latitude},${dest.longitude}',
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
  } catch (e) {
    print("[TEMP] [WARNING] BACKEND REQUEST FAIL! $e");
    systemVariablesProvider.setAppCurrentState = SystemState.backendRequestFail;
    return {};
  }
}
