import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/providers/provider_search_details.dart';

import '../classes/nominatim_response.dart';

/// Calls Nominatim Public API to do searches. SearchDetailsProvider and SearchFieldType
/// are used to know which textfield did the connection fail occur.
Future<List<NominatimPlace>> searchPlaces(
  String query,
  SearchDetailsProvider searchDetailsProvider,
  SearchFieldType searchFieldType,
) async {
  // randomized user agent
  final user_agent = "user_me_${Random().nextInt(1000000)}";
  final uri = Uri.parse('https://nominatim.openstreetmap.org/search').replace(
    queryParameters: {
      'q': query,
      'countrycodes': 'PH',
      'format': 'json',
      'limit': '10',
      'user_agent': user_agent,
    },
  );
  try {
    final response = await http.get(
      uri,
      headers: {'User-Agent': 'SakenPH/1.0'},
    );

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
  } on http.ClientException catch (e) {
    List<NominatimPlace> errorReturn = [];
    errorReturn.add(
      NominatimPlace(
        placeId: -1,
        osmType: "-1",
        osmId: -1,
        lat: -1,
        lon: -1,
        name: "Rate Limit has reached",
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

    switch (searchFieldType) {
      case SearchFieldType.from:
        searchDetailsProvider.setIsNominatimSearchFailed_TypeFrom = true;
      case SearchFieldType.to:
        searchDetailsProvider.setIsNominatimSearchFailed_TypeTo = true;
    }

    return errorReturn;
  }
}
