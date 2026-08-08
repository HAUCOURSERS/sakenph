import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sakenph/globals/variables.dart' as global_vars;
import 'package:sakenph/classes/jeepney_route.dart';
import 'package:sakenph/classes/terminal_class.dart';
import 'package:sakenph/api/local/env.dart';

/// Attempts to get json results by submitting origin and destination [LatLng] values.
/// Returns a nullable <code>Map&lt;String, dynamic&gt;</code> value. BuildContext is passed
/// to allow for context.read() calls to be used in this function.
Future<Map<String, dynamic>> queryForShortestPath(
  LatLng origin,
  LatLng dest,
  BuildContext context, {
  bool traffic = false,
}) async {
  //SystemVariablesProvider systemVariablesProvider = context.read<SystemVariablesProvider>();

  try {
    final startTime = DateTime.now();
    String localIp = global_vars.localIP;
    // Position gpsLocation = await determinePosition();
    print(
      'http://${Env.API_ENDPOINT_LINK}:8000/k_shortest_paths?src=${origin.latitude},${origin.longitude}&dest=${dest.latitude},${dest.longitude}&traffic=$traffic',
    );

    final response = await http.get(
      Uri.parse(
        // local backend
        'http://$localIp:8000/k_shortest_paths?src=${origin.latitude},${origin.longitude}&dest=${dest.latitude},${dest.longitude}&algo=astar&debug=true',

        // AWS EC2
        //'http://${Env.API_ENDPOINT_LINK}:8000/k_shortest_paths?src=${origin.latitude},${origin.longitude}&dest=${dest.latitude},${dest.longitude}&traffic=$traffic',
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
    // will be developed IF will be developed.
    // systemVariablesProvider.setAppCurrentState = SystemState.backendRequestFail;
    return {};
  }
}

// Fetches jeepney routes from the backend service and returns a list of JeepneyRoute objects.
Future<List<JeepneyRoute>> fetchJeepRoutes() async {
  final response = await http.get(
    Uri.parse(
      //'http://${Env.API_ENDPOINT_LINK}:8000/jeep_routes',
      'http://${global_vars.localIP}:8000/jeep_routes',
    ), // local backend service link for ui toggle
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

/// Fetches all TODA terminal points from the backend service.
Future<List<Terminal>> fetchTodaTerminals() async {
  print(
    "[TEMP] TRY TO PARSE: ${'http://${global_vars.localIP}:8000/trike_terminals_list'}",
  );
  final response = await http.get(
    Uri.parse(
      //'${Env.API_ENDPOINT_LINK}/trike_terminals_list',
      'http://${global_vars.localIP}:8000/trike_terminals_list',
    ), // local backend service link for TODA Terminals
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to load TODA terminals');
  }

  final Map<String, dynamic> body = jsonDecode(response.body);
  final List<dynamic> terminals = body['terminalList'] ?? [];

  return terminals.asMap().entries.map((entry) {
    final index = entry.key;
    final terminal = entry.value as Map<String, dynamic>;
    final coords = terminal['coordinates'] as Map<String, dynamic>;

    return Terminal(
      id: index + 1,
      name: terminal['terminalName']?.toString() ?? 'TODA Terminal',
      longitude: (coords['long'] as num).toDouble(),
      latitude: (coords['lat'] as num).toDouble(),
      type: 'trike',
    );
  }).toList();
}
