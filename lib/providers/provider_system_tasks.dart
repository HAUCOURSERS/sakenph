import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_search_details.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/provider_system_vars.dart';

class SystemTasksProvder extends ChangeNotifier {
  // ignore: non_constant_identifier_names
  bool _isRunning_repeatingTask = false;

  // Dependencies
  SystemVariablesProvider? _systemVariablesProvider;
  SearchDetailsProvider? _searchDetailsProvider;
  MapHelperProvider? _mapHelperProvider;

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
    _startStream();
  }

  // ignore: non_constant_identifier_names
  void stop_repeatingTask() {
    print("Stopped Streaming");
    _stopStream();
  }

  StreamSubscription<Position>? _positionStream;

  void _startStream() async {
    bool hasPerms = await getGeolocatorPermission();
    if (!hasPerms) return;

    print("[TEMP] Stream started");
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0, // update every 10 meters
    );

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position position) {
          print(
            "[TEMP] POSITION UPDATE: ${position.latitude} ${position.longitude} | COMPASS: ${_mapHelperProvider!.getUserCompassRotation}",
          );
          _mapHelperProvider?.mapWidgetController.addUserMarker(
            LatLng(position.latitude, position.longitude),
            _mapHelperProvider!.getUserCompassRotation,
          );
          //print('${position.latitude}, ${position.longitude}');
        });
  }

  void _stopStream() {
    _positionStream!.cancel();
    _positionStream = null;
  }
}
