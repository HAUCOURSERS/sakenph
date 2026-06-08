import 'package:flutter/material.dart';
import 'package:sakenph/classes/nominatim_response.dart' show NominatimPlace;

class SearchDetailsProvider extends ChangeNotifier {
  bool isLoading = false;
  List<NominatimPlace> fromLocResults = [];
  bool isFromLocTextfieldEmpty = true; // Textfield is empty on default

  /// For logic to be able to edit the contents of the textfields
  TextEditingController fromLocController = TextEditingController();
  TextEditingController toLocController = TextEditingController();

  FocusNode toLocFocusNode = FocusNode();

  NominatimPlace? selectedOriginLocation;
  NominatimPlace? selectedDestinationLocation;

  /// Used to help the background widget to decide whether to display the widget that holds
  /// the loading icon and the results ListView
  void setIsFromLocTextfieldEmpty(bool val) {
    // It's useless to run notifyListeners() if the passed value is the same as
    // the existing value
    if (isFromLocTextfieldEmpty == val) return;

    isFromLocTextfieldEmpty = val;
    notifyListeners();
  }

  /// Tries to clear search results if the user attempts to type more again
  void tryToEraseFromLocResults() {
    if (fromLocResults.isEmpty) return;

    fromLocResults.clear();
    notifyListeners();
  }

  void setFromLocResults(List<NominatimPlace> resultList) {
    fromLocResults = resultList;
    notifyListeners();
  }
}
