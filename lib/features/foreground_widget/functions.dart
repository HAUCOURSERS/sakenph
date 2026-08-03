import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/computations.dart';
import 'package:sakenph/globals/functions/formattings.dart';
import 'package:sakenph/globals/variables.dart' as global_vars show localIP;
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_system_tasks.dart';
import 'package:sakenph/providers/provider_system_vars.dart';
import 'package:sakenph/api/backend_service.dart';
import 'package:sakenph/classes/terminal_class.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert' as json_enc;

/// Currently has no uses
Future<String> reverseGeocode({
  required double longitude,
  required double latitude,
}) async {
  final uri = Uri.parse(
    'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=jsonv2&addressdetails=1&zoom=18',
  );

  final response = await http.get(
    uri,
    headers: {
      'User-Agent': 'SakenPH/1.0',
      'Accept-Language': 'en',
    },
  ).timeout(const Duration(seconds: 8));

  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonObject = jsonDecode(response.body);
    final address = jsonObject['address'] as Map<String, dynamic>?;

    if (address != null) {
      if (address.containsKey('barangay')) {
        final rawValue = address['barangay'];
        if (rawValue is String && rawValue.isNotEmpty) {
          return 'Barangay $rawValue';
        }
      }

      final displayName = jsonObject['display_name'] as String?;
      if (displayName != null && displayName.isNotEmpty) {
        final parts = displayName.split(',').map((p) => p.trim()).toList();
        return parts.take(2).join(', ');
      }
    }

    return 'Unknown location';
  } else {
    throw Exception('Failed to load JSON');
  }
}

/// Currently used to test connection towards backend.
/// If connection is successful, it will return "Hello from FastAPI!"
Future<Map<String, dynamic>> fetchData() async {
  String localIp = global_vars.localIP;
  final response = await http.get(
    Uri.parse('http://${localIp}:8000/flutterTest'),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load JSON');
  }
}

/// Fetch TODA terminals from backend and enrich each terminal with a barangay value
/// by calling Nominatim reverse geocode for each one. This respects Nominatim
/// rate limits by delaying between requests (default 1100ms).
Future<List<Terminal>> fetchAndEnrichTodaTerminals({
  Duration delayBetween = const Duration(milliseconds: 200),
}) async {
  final terminals = await fetchTodaTerminals();

  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('toda_barangay_cache');
  Map<String, String> cache = {};
  if (raw != null && raw.isNotEmpty) {
    try {
      cache = Map<String, String>.from(json_enc.jsonDecode(raw));
    } catch (_) {
      cache = {};
    }
  }

  bool updated = false;

  for (final t in terminals) {
    final key = t.id.toString();

    // If we already have a cached barangay, use it
    if (cache.containsKey(key) && cache[key] != null && cache[key]!.isNotEmpty && cache[key] != 'Unknown location') {
      t.barangay = cache[key];
      continue;
    }

    try {
      // Query Nominatim for barangay
      final label = await reverseGeocode(
        latitude: t.latitude,
        longitude: t.longitude,
      );

      if (label.isNotEmpty && label != 'Unknown location') {
        t.barangay = label;
        cache[key] = label;
        updated = true;
      } else {
        t.barangay = null;
      }
    } catch (e) {
      // network or parsing error: leave barangay null
      t.barangay = null;
    }

    // Respect Nominatim usage policy: do not flood the service. Delay between requests.
    await Future.delayed(delayBetween);
  }

  if (updated) {
    await prefs.setString('toda_barangay_cache', json_enc.jsonEncode(cache));
  }

  return terminals;
}

/// To get location perms
Future<bool> handleLocationPermission(BuildContext context) async {
  if (!context.mounted) return false;
  bool serviceEnabled;
  LocationPermission permission;

  ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Location services are disabled. Please enable the services',
        ),
      ),
    );
    return false;
  }
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Location permissions are denied')),
      );
      return false;
    }
  }
  if (permission == LocationPermission.deniedForever) {
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Location permissions are permanently denied, we cannot request permissions.',
        ),
      ),
    );
    return false;
  }
  return true;
}

/// Runs the necessary code across context providers to setup the traveling state
void startTraveling(BuildContext context) async {
  // Hide every other option to focus on travelling
  context.read<SystemVariablesProvider>().setBackgroundWidgetVisibility = false;
  context.read<SystemVariablesProvider>().setAppCurrentState =
      SystemState.isCurrentlyTravelling;

  // Immediately set the marker
  LatLng coords = context.read<MapHelperProvider>().getUserCurrentGeoLoc;
  context.read<MapHelperProvider>().mapWidgetController.flyToLoc(coords);

  context.read<SystemTasksProvder>().start_repeatingTask();

  await context.read<MapHelperProvider>().mapWidgetController.addUserMarker(
    coords,
    0,
  );
}

/// Upon providing the JSON return of backend along with the route_id of your choice,
/// it will return a List<(String, double)> of data.
///
/// Data format:
/// - Walk/Jeep Name
/// - Color
/// - Distance in meters
/// - Fare Rate (Formatted or Blank if no fare)
List<(String, String, double, String)> buildTravelDetails(
  Map<String, dynamic> routeData,
  String route_id,
) {
  List<(String, String, double, String)> returnDetails = [];
  for (final entry in routeData["routes"][route_id]) {
    double distanceInKM = 0;
    // Each entry here represents a chop piece in the route caused by switching between
    // transpo modes like: walk -> jeep -> walk
    List<LatLng> geometryDetails = (entry["geometry"] as List<dynamic>).map((
      item,
    ) {
      final coords = (item as List<dynamic>)
          .map((coord) => (coord as num).toDouble())
          .toList();
      return LatLng(coords[1], coords[0]);
    }).toList();

    // At this point, start computing the distance between in km
    for (int i = 0; i < geometryDetails.length - 1; i++) {
      distanceInKM += getDistanceFromLatLonInKm(
        geometryDetails[i].latitude,
        geometryDetails[i].longitude,
        geometryDetails[i + 1].latitude,
        geometryDetails[i + 1].longitude,
      );
    }
    String routeColor = entry["mode"]["details"]["color"].toString();
    double fareRegular = entry["mode"]["details"]["fare"]["regular"];
    double fareDiscounted = entry["mode"]["details"]["fare"]["discounted"];
    String modeType = entry["mode"]["type"].toString();
    if (modeType == "walk") {
      returnDetails.add(("Walk", routeColor, (distanceInKM * 1000), ""));
    } else if (modeType == "jeep") {
      String jeepName = entry["mode"]["details"]["name"].toString();
      returnDetails.add((
        formatLabelForJeepneyName(jeepName),
        routeColor,
        (distanceInKM * 1000),
        "${fareRegular.toStringAsFixed(2)}₱ / ${fareDiscounted.toStringAsFixed(2)}₱",
      ));
    } else if (modeType == "trike") {
      returnDetails.add((
        // TODO: Add TODA Name here (For backend)
        "Tricycle",
        routeColor,
        (distanceInKM * 1000),
        "${fareRegular.toStringAsFixed(2)}₱ / ${fareDiscounted.toStringAsFixed(2)}₱",
      ));
    }
  }

  return returnDetails;
}

/// Returns a grouped double values that totals the fare amount
(double, double) computeFareTotalForRoute(
  Map<String, dynamic> routeData,
  String route_id,
) {
  double totalAmt = 0;
  double totalAmtDiscounted = 0;

  for (final entry in routeData["routes"][route_id]) {
    Map<String, dynamic> fareDetails = entry["mode"]["details"];
    totalAmt += fareDetails["fare"] == null
        ? 0
        : double.parse(fareDetails["fare"]["regular"].toString());
    totalAmtDiscounted += fareDetails["fare"] == null
        ? 0
        : double.parse(fareDetails["fare"]["discounted"].toString());
  }

  return (totalAmt, totalAmtDiscounted);
}
