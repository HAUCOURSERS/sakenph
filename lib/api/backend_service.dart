// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/api/local/env.dart';
import 'package:sakenph/globals/variables.dart' as global_vars;
import 'package:sakenph/classes/jeepney_route.dart';

/// Attempts to get json results by submitting origin and destination [LatLng] values.
/// Returns a nullable <code>Map&lt;String, dynamic&gt;</code> value. BuildContext is passed
/// to allow for context.read() calls to be used in this function.
Future<Map<String, dynamic>> queryForShortestPath(
  LatLng origin,
  LatLng dest,
  BuildContext context,
) async {
  //SystemVariablesProvider systemVariablesProvider = context.read<SystemVariablesProvider>();

  try {
    final startTime = DateTime.now();
    String localIp = global_vars.localIP;
    // Position gpsLocation = await determinePosition();
    print(
      'http://$localIp:8000/k_shortest_paths?src=${origin.latitude},${origin.longitude}&dest=${dest.latitude},${dest.longitude}&algo=astar&debug=true',
    );

<<<<<<< HEAD
    final response = await http.get(
      Uri.parse(
        // local backend
        'http://$localIp:8000/k_shortest_paths?src=${origin.latitude},${origin.longitude}&dest=${dest.latitude},${dest.longitude}&algo=astar&debug=true',

        // AWS EC2
        //'${Env.API_ENDPOINT_LINK}k_shortest_paths?src=${origin.latitude},${origin.longitude}&dest=${dest.latitude},${dest.longitude}',
      ),
    );
=======
      // local backend only use when updating the backend service
      //'http://10.0.2.2:8000/k_shortest_paths?src=${origin.latitude},${origin.longitude}&dest=${dest.latitude},${dest.longitude}',
      
      // AWS EC2 
      'http://ec2-18.142.233.77.ap-southeast-1.compute.amazonaws.com:8000/k_shortest_paths?src=${origin.latitude},${origin.longitude}&dest=${dest.latitude},${dest.longitude}',
    ),
  );
>>>>>>> origin/temp-old-version

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
    // will be developed IF will be developed.
    // systemVariablesProvider.setAppCurrentState = SystemState.backendRequestFail;
    return {};
  }
}

// Fetches jeepney routes from the backend service and returns a list of JeepneyRoute objects.
Future<List<JeepneyRoute>> fetchJeepRoutes() async {
  final response = await http.get(
    Uri.parse('http://18.142.233.77:8000/jeep_routes'),       // local backend service link for ui toggle
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to load jeep routes');
  }

  final Map<String, dynamic> body = jsonDecode(response.body);
  final List<dynamic> routes = body['routes'];

  return routes
      .map((route) => JeepneyRoute.fromJson(route as Map<String, dynamic>))
      .toList();
  }

