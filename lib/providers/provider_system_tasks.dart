import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/globals/functions/computations.dart';
import 'package:sakenph/globals/functions/system.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_search_details.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/provider_system_vars.dart';

class SystemTasksProvder extends ChangeNotifier {
  // //////////////////////////////////////////////////////////
  // Dependencies
  // //////////////////////////////////////////////////////////

  SystemVariablesProvider? _systemVariablesProvider;
  SearchDetailsProvider? _searchDetailsProvider;
  MapHelperProvider? _mapHelperProvider;

  // //////////////////////////////////////////////////////////
  // Variables
  // //////////////////////////////////////////////////////////

  StreamSubscription<Position>? _positionStream; // holds position listener
  Timer?
  _locationUpdater; // holds the timer that updates the user marker on the map every 500ms
  Timer? _testTimer; // for testing purposes only

  /// Mounts the required providers to this provider. This is required before starting any repeating tasks.
  void mountProviders(BuildContext context) {
    _systemVariablesProvider = context.read<SystemVariablesProvider>();
    _searchDetailsProvider = context.read<SearchDetailsProvider>();
    _mapHelperProvider = context.read<MapHelperProvider>();
  }

  // //////////////////////////////////////////////////////////
  // Repeating Tasks
  // //////////////////////////////////////////////////////////

  /// Checks if the required dependencies such as provider pointers are mounted
  /// to this provider.
  bool _checkDependencies() {
    return _systemVariablesProvider != null &&
        _searchDetailsProvider != null &&
        _mapHelperProvider != null;
  }

  /// Start repeating tasks. mountProviders must be executed first before doing anything
  // ignore: non_constant_identifier_names
  void start_repeatingTask() {
    if (!_checkDependencies()) {
      print("DEPENDENCIES FOR START_REPEATINGTASK() MISSING");
      return;
    }
    _locationUpdater = Timer.periodic(Duration(milliseconds: 500), (
      timer,
    ) async {
      //print("UPDATING MARKER ATTRIBUTES");
      await _mapHelperProvider!.mapWidgetController.addUserMarker(
        _mapHelperProvider!.getUserCurrentGeoLoc,
        _mapHelperProvider!.getRotationFromLatLngHistory(),
      );
    });

    // for testing
    _testTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      print(
        "[TEMP] Distance till destination: ${getDistanceFromLatLonInKm(_mapHelperProvider!.getUserCurrentGeoLoc.latitude, _mapHelperProvider!.getUserCurrentGeoLoc.longitude, _mapHelperProvider!.getSelectedToLocationDetails!.latitude, _mapHelperProvider!.getSelectedToLocationDetails!.longitude) * 1000} m",
      );
    });

    _startStream();
  }

  /// Stop repeating tasks. mountProviders must be executed first before doing anything
  // ignore: non_constant_identifier_names
  void stop_repeatingTask() {
    _locationUpdater!.cancel();
    _testTimer!.cancel();
    _stopStream();
  }

  /// Starts the stream to listen for geolocation updates. mountProviders must be executed first before doing anything
  void _startStream() async {
    bool hasPerms = await getGeolocatorPermission();
    if (!hasPerms) return;

    print("[TEMP] Stream started");
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1, // update every 1 meter
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _mapHelperProvider!.saveLatLngForRotationComputation(
              LatLng(position.latitude, position.longitude),
            );
            _mapHelperProvider!.setUserCurrentGeoLoc = LatLng(
              position.latitude,
              position.longitude,
            );
          },
        );
  }

  /// Stops the stream to listen for geolocation updates. mountProviders must be executed first before doing anything
  void _stopStream() async {
    _positionStream!.cancel();
    _positionStream = null;
    await Future.delayed(Duration(seconds: 2));
  }
}
