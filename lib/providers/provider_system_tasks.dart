import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/globals/functions.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_search_details.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/provider_system_vars.dart';

class SystemTasksProvder extends ChangeNotifier {
  // Dependencies
  SystemVariablesProvider? _systemVariablesProvider;
  SearchDetailsProvider? _searchDetailsProvider;
  MapHelperProvider? _mapHelperProvider;

  // Variables

  StreamSubscription<Position>? _positionStream; // holds position listener
  Timer? _locationUpdater;

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
        _mapHelperProvider!.getUserCompassRotation,
      );
    });
    _startStream();
  }

  // ignore: non_constant_identifier_names
  void stop_repeatingTask() {
    print("Stopped Streaming");
    _locationUpdater!.cancel();

    _stopStream();
  }

  void _startStream() async {
    bool hasPerms = await getGeolocatorPermission();
    if (!hasPerms) return;

    print("[TEMP] Stream started");
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0, // update every 10 meters
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _mapHelperProvider!.setUserCurrentGeoLoc = LatLng(
              position.latitude,
              position.longitude,
            );
          },
        );
  }

  void _stopStream() async {
    _positionStream!.cancel();
    _positionStream = null;
    await Future.delayed(Duration(seconds: 2));
    _mapHelperProvider!.mapWidgetController.clearLayersAndSources();
  }
}
