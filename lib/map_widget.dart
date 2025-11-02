
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sakenph/auth_service.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sakenph/database_service.dart';
import 'package:sakenph/terminal_class.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => _MapWidget();
}

class _MapWidget extends State<MapWidget> {
  MapLibreMapController? _controller;
  String mapStyle = "";

  String? styleJson;
  Future<void> _loadStyle() async {
    final json = await rootBundle.loadString('assets/map_styles/osm_bright2.json');

    setState(() => mapStyle = json);
  }

    @override
    void initState() {
      super.initState();
      _loadStyle();
    }

 Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print("EYY DID U DO SOMETHING");

    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the 
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    print("HEllo");
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale 
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately. 
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    } 

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
        styleString: mapStyle,
        
        onMapCreated: (c) {
          _controller = c;
        },
        onStyleLoadedCallback: () async {
          // final terminalList = await DatabaseService().terminalList;

          // for (Terminal t in terminalList) {
          //   await _controller?.addSource(
          //     'source_${t.id}',
          //     GeojsonSourceProperties(
          //       data: {
          //         'type': 'FeatureCollection',
          //         'features': [
          //           {
          //             'type': 'Feature',
          //             'geometry': {
          //               'type': 'Point',
          //               'coordinates': [t.longitude, t.latitude],
          //             },
          //           },
          //         ],
          //       },
          //     ),
          //   );

          //   await _controller?.addLayer(
          //     'source_${t.id}',
          //     'layer_${t.id}',
          //     const SymbolLayerProperties(
          //       iconImage: 'bus',
          //       iconSize: 1.5,
          //     ),
          //   );
          // }
        },
        initialCameraPosition: const CameraPosition(
          target: LatLng(15, 120.55),
          zoom: 10,
        ),
      );
  }
}