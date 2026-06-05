import 'dart:convert';

import 'package:http/http.dart' as http;

import '../classes/nominatim_response.dart';

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
    List<NominatimPlace> returnList = jsonList
        .map((e) => NominatimPlace.fromJson(e))
        .toList();

    if (returnList.isNotEmpty) {
      return jsonList.map((e) => NominatimPlace.fromJson(e)).toList();
    } else {
      List<NominatimPlace> errorReturn = [];
      errorReturn.add(
        NominatimPlace(
          placeId: -1,
          osmType: "-1",
          osmId: -1,
          lat: -1,
          lon: -1,
          name: "No Places Found",
          displayName:
              "No valid places found. Please try entering something else",
          className: "No Places Found",
          type: "null",
          placeRank: -1,
          importance: -1,
          addressType: "null",
          boundingBox: ["null"],
        ),
      );
      return errorReturn;
    }
  } else {
    List<NominatimPlace> errorReturn = [];
    errorReturn.add(
      NominatimPlace(
        placeId: -1,
        osmType: "-1",
        osmId: -1,
        lat: -1,
        lon: -1,
        name: "No Places Found",
        displayName:
            "An error has occurred while fetching location name suggestions",
        className: "No Places Found",
        type: "null",
        placeRank: -1,
        importance: -1,
        addressType: "null",
        boundingBox: ["null"],
      ),
    );
    return errorReturn;
  }
}
