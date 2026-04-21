import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sakenph/classes/nominatim_response.dart';
import 'package:http/http.dart' as http;

/// Calls Nominatim Public API to do searches
Future<List<NominatimPlace>> searchPlaces(String query) async {
  final uri = Uri.parse('https://nominatim.openstreetmap.org/search').replace(
    queryParameters: {
      'q': query,
      'countrycodes': 'PH',
      'format': 'json',
      'limit': '10',
    },
  );

  final response = await http.get(uri, headers: {'User-Agent': 'SakenPH/1.0'});

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    //print(jsonDecode(response.body));
    return jsonList.map((e) => NominatimPlace.fromJson(e)).toList();
  } else {
    throw Exception('Failed to load places');
  }
}

/// Currently has no uses
Future<String> reverseGeocode({
  required double longitude,
  required double latitude,
}) async {
  final response = await http.get(
    Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=jsonv2',
    ),
  );

  if (response.statusCode == 200) {
    Map<String, dynamic> jsonObject = jsonDecode(response.body);

    return jsonObject['display_name'];
  } else {
    throw Exception('Failed to load JSON');
  }
}

/// Currently used to test connection towards backend.
/// If connection is successful, it will return "Hello from FastAPI!"
Future<Map<String, dynamic>> fetchData() async {
  String localIp = "192.168.68.58";
  final response = await http.get(
    Uri.parse('http://${localIp}:8000/flutterTest'),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load JSON');
  }
}

/// This function is made to turn a multi-line widget into a single
/// method call for code cleanliness.
Widget loadingDisplay() {
  return GestureDetector(
    onTap: () {
      print("Wahh");
    },
    child: Container(height: 30, child: const Text("Loading..")),
  );
}
