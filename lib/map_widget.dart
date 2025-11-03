import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sakenph/auth_service.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
    import 'dart:math';
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

  

  Future<void> _loadStyle() async {
    final json = await rootBundle.loadString('assets/map_styles/osm_bright2.json');

    setState(() => mapStyle = json);
  }

    @override
    void initState() {
      super.initState();
      _loadStyle();
    }

  Future<void> addTerminalLayers() async {
    final terminalList = await DatabaseService().terminalList;

    for (Terminal t in terminalList) {
      await _controller?.addSource(
        'source_${t.id}',
        GeojsonSourceProperties(
          data: {
            'type': 'FeatureCollection',
            'features': [
              {
                'type': 'Feature',
                'geometry': {
                  'type': 'Point',
                  'coordinates': [t.longitude, t.latitude],
                },
              },
            ],
          },
        ),
      );

      await _controller?.addLayer(
        'source_${t.id}',
        'layer_${t.id}',
        const SymbolLayerProperties(
          iconImage: 'bus',
          iconSize: 1.5,
        ),
      );
    }
  }

 Future<Position> determinePosition() async {
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
        onMapLongClick: (point, coordinates) async {

          _controller?.removeLayer('layer_selectedPoint');
          _controller?.removeSource('source_selectedPoint');

          await _controller?.addSource(
            'source_selectedPoint',
            GeojsonSourceProperties(
              data: {
                'type': 'FeatureCollection',
                'features': [
                  {
                    'type': 'Feature',
                    'geometry': {
                      'type': 'Point',
                      'coordinates': [coordinates.longitude, coordinates.latitude],
                    },
                  },
                ],
              },
            ),
          );

          await _controller?.addLayer(
            'source_selectedPoint',
            'layer_selectedPoint',
            const SymbolLayerProperties(
              iconImage: 'circle_stroked',
              iconSize: 1.5,
            ),
          );
          
          if (context.mounted) {
            final sheetController = Scaffold.of(context).showBottomSheet(
              (context) {
                return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      color: const Color.fromARGB(255, 227, 241, 253)
                    ),
                    width: MediaQuery.of(context).size.width,
                    height: 300, 
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text('Point'),
                            Text('${coordinates.latitude}, ${coordinates.longitude}')
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          }, 
                          child: Container(
                            width: 320,
                            decoration: BoxDecoration(
                              color: Colors.blue, 
                              borderRadius: BorderRadius.circular(32)
                            ),
                            padding: EdgeInsets.all(10),
                            child: Text(
                              "Add Terminal",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                              ),
                            )
                          )
                        )
                      
                      ],
                    )
                  );
              }
            );

            sheetController.closed.then((E) {
              _controller?.removeLayer('layer_selectedPoint');
              _controller?.removeSource('source_selectedPoint');
            });
          }
        },
        onStyleLoadedCallback: addTerminalLayers,
        initialCameraPosition: const CameraPosition(
          target: LatLng(15, 120.55),
          zoom: 10,
        ),
      );
  }
}