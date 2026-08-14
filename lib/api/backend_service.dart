import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/variables.dart' as global_vars;
import 'package:sakenph/classes/jeepney_route.dart';
import 'package:sakenph/classes/terminal_class.dart';
import 'package:sakenph/api/local/env.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

void startComputingForRoutes(BuildContext context) async {
  SystemVariablesProvider systemVariablesProvider = context
      .read<SystemVariablesProvider>();
  MapHelperProvider mapHelperProvider = context.read<MapHelperProvider>();

  systemVariablesProvider.setAppCurrentState =
      SystemState.waitingForBackendResponse;

  Map<String, dynamic> backendResponse = await _queryForShortestPath(
    mapHelperProvider.getSelectedFromLocationDetails!,
    mapHelperProvider.getSelectedToLocationDetails!,
    context,
    traffic: systemVariablesProvider.includeTraffic,
  );
  if (backendResponse.isEmpty) {
    // queryForShortestPath() will always return a non-empty map if backend response worked.
    throw UnimplementedError(
      "Note to developer: Add a retry button here since the backend response failed.",
    );
  } else {
    mapHelperProvider.setSuggestedShortestPaths = backendResponse;
    systemVariablesProvider.setAppCurrentState =
        SystemState.showSuggestedRoutes;
  }
}

/// Attempts to get json results by submitting origin and destination [LatLng] values.
/// Returns a nullable <code>Map&lt;String, dynamic&gt;</code> value. BuildContext is passed
/// to allow for context.read() calls to be used in this function.
Future<Map<String, dynamic>> _queryForShortestPath(
  LatLng origin,
  LatLng dest,
  BuildContext context, {
  bool traffic = false,
}) async {
  //SystemVariablesProvider systemVariablesProvider = context.read<SystemVariablesProvider>();

  try {
    final startTime = DateTime.now();
    final response = await http.get(
      Uri.parse(
        // AWS EC2
        'http://${Env.API_ENDPOINT_LINK}:8000/k_shortest_paths?src=${origin.latitude},${origin.longitude}&dest=${dest.latitude},${dest.longitude}&traffic=$traffic',
        
      ),
    );

    if (response.statusCode == 200) {
      final endTime = DateTime.now();
      final Map<String, dynamic> json = jsonDecode(response.body);
      return json;
    } else {
      return {};
    }
  } catch (e) {
    // will be developed IF will be developed.
    // systemVariablesProvider.setAppCurrentState = SystemState.backendRequestFail;
    return {};
  }
}

// Fetches jeepney routes from the backend service and returns a list of JeepneyRoute objects.
Future<List<JeepneyRoute>> fetchJeepRoutes() async {
  final response = await http.get(
    Uri.parse(
      'http://${Env.API_ENDPOINT_LINK}:8000/jeep_routes',
    ), // local backend service link for ui toggle
  );
  

  final Map<String, dynamic> body = jsonDecode(response.body);
  final List<dynamic> routes = body['routes'];

  return routes
      .map((route) => JeepneyRoute.fromJson(route as Map<String, dynamic>))
      .toList();
}

/// Fetches all TODA terminal points from the backend service.
Future<List<Terminal>> fetchTodaTerminals() async {
  final response = await http.get(
    Uri.parse(
      'http://${Env.API_ENDPOINT_LINK}:8000/trike_terminals_list',
    ),
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
      barangay: terminal['locationName']?.toString(),
    );
  }).toList();
}
