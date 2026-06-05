import 'package:flutter/material.dart';
import 'package:sakenph/classes/nominatim_response.dart' show NominatimPlace;

class SearchResultsProvider extends ChangeNotifier {
  List<NominatimPlace> fromLocResults = [];
}
