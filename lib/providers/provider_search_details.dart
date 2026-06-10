import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/classes/nominatim_response.dart' show NominatimPlace;
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

class SearchDetailsProvider extends ChangeNotifier {

  bool isLoading = false;
  List<NominatimPlace> fromLocResults = [];
  bool isFromLocTextfieldEmpty = true; // Textfield is empty on default

  /// For logic to be able to edit the contents of the textfields
  TextEditingController fromLocController = TextEditingController();
  TextEditingController toLocController = TextEditingController();

  FocusNode toLocFocusNode = FocusNode();

  Location? _selectedFromLocationDetails;
  NominatimPlace? _selectedDestinationLocationDetails;


  bool get isFromLocationDetailsEmpty => _selectedFromLocationDetails != null;


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

  /// Saves the search results done in the FromLocation TextField. Once the results are saved
  /// in the provider variable, the background widget would listen for changes in the variable value
  /// and then start building the search result widgets.
  void setFromLocSearchResults(List<NominatimPlace> resultList) {
    fromLocResults = resultList;
    notifyListeners();
  }

  /// Compact function that is solely for the button that suggests to use your current location.
  /// 
  /// BuildContext pointer is required to properly transition to the ToLocation UI because
  /// fetching the user's current location is async and changing the widget state should only
  /// happen after it's done saving current user location details.
  void setFromLocationDetails_usingCurrentLocation(BuildContext contextPointer) async {
    await Future.delayed(Duration(milliseconds: 50));

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _setFromLocationDetails(position.latitude, position.longitude, "Your Current Location");
    contextPointer.read<SystemVariablesProvider>().setBackWidgetCurrentState(SystemStateEnum.gatheringToLoc);
  }

  /// Takes in a [NominatimPlace] object and only takes the latitude, longitude
  /// and name details
  void setFromLocationDetails(NominatimPlace nomiDetails) {
    _setFromLocationDetails(nomiDetails.lat, nomiDetails.lon, nomiDetails.name);
  }

  /// The main <code>setFromLocationDetails</code> method. Only the <code>lat, lon, name</code>
  /// details are needed to perform app logic.
  /// 
  /// FromLocation will be used alongside ToLocation to compute optimal route.
  void _setFromLocationDetails(double lat, double lon, String name) {
    fromLocController.text = name;
    _selectedFromLocationDetails = Location(latitude: lat, longitude: lon, timestamp: DateTime.now());
    toLocFocusNode.requestFocus();
    notifyListeners();
  }


}
