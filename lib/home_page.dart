import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sakenph/auth_service.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  MapLibreMapController? _controller;
  // String mapStyle = "";

  // String? styleJson;
  // Future<void> _loadStyle() async {
  //   final json = await rootBundle.loadString('assets/map_styles/osm_bright.json');

  //   setState(() => mapStyle = json);
  // }

  //   @override
  //   void initState() {
  //     super.initState();
  //     _loadStyle();
  //   }

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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: ListTile(
          title: Text("Test"),
          trailing: PopupMenuButton(
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'Log out', child: Text('Log out')),
            ],
            onSelected: (value) async {
              if (value=='Log out') {
                try {
                  await AuthService().signOut();
                } catch (e) {
                  return;
                }
              }
            }
          )
        ),
      ),
      body: MapLibreMap(
        // ignore: avoid_redundant_argument_values --- EXAMPLE ---
        styleString: 'https://tiles.openfreemap.org/styles/liberty',
        
        onMapCreated: (c) {
          _controller = c;
        },
        onStyleLoadedCallback: () async {
          await _controller?.addSource(
            'source',
            GeojsonSourceProperties(
              data: {
                'type': 'FeatureCollection',
                'features': [
                  {
                    'type': 'Feature',
                    'geometry': {
                      'type': 'Point',
                      'coordinates': [120.5801615201509, 15.168811696245177],
                    },
                  },
                ],
              },
            ),
          );

          await _controller?.addLayer(
            'source',
            'YOYOYOYOYOOYOYOOOOOOOOOOOOOOOOOO',
            const SymbolLayerProperties(
              iconImage: 'bus',
              iconSize: 1.5,
            ),
          );
        },
        initialCameraPosition: const CameraPosition(
          target: LatLng(15, 120.55),
          zoom: 10,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final c = _controller;
          if (c == null) return;

          Position position = await _determinePosition();
          print('pos VVV');
          print(position);
          await c.animateCamera(
            CameraUpdate.newCameraPosition(
              const CameraPosition(target: LatLng(15, 120.55), zoom: 10),
            ),
          );
        },
        child: const Icon(Icons.flight),
      ),
    );
  }
}