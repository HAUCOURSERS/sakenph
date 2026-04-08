import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:http/http.dart' as http;
import 'package:sakenph/database_service.dart';
import 'package:sakenph/terminal_class.dart';
import 'dart:developer';

class MapWidget extends StatefulWidget {

  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => _MapWidget();
}

class _MapWidget extends State<MapWidget> {
  MapLibreMapController? _controller;
  String mapStyle = "";

  
  // Loads custom map style from assets based on Stadia Map's OSM Bright style
  Future<void> _loadStyle() async {
    final json = await rootBundle.loadString('assets/map_styles/osm_bright2.json');

    setState(() => mapStyle = json);
  }

    @override
    void initState() {
      super.initState();
      _loadStyle();
    }

  // UNUSED FUNCTION FOR NOW: used when clicked on a TODA Terminal icon
  Future<void> clickedTLayer(String layerId) async {
    print("In function:");
    if (context.mounted) {
    print("Context is mounted");

      int terminalId = int.parse(layerId.replaceAll('layer_', ""));
      final Terminal tappedTerminal = await DatabaseService().getTerminalById(terminalId);
    print("Terminal retrieved");

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
                      Text('Jeepney Terminal'),
                      Text(tappedTerminal.name)
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
  }

  // Function used
  void addLayers() {
    addTerminalLayers();
    addTodaLayers();
  }

  Future<void> addTodaLayers() async {
    final todaList = await DatabaseService().todaList;

    for (Terminal t in todaList) {
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
          iconImage: 'toda',
          iconSize: 0.25,
        ),
        minzoom: 12
      );
    }
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
        minzoom: 8
      );
    }
  }

 Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
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
        
        onMapCreated: (c) async {

          // Gets point of current location of GPS
          Position gpsLocation = await determinePosition();

          _controller = c;

          // Function that triggers when you click on a TODA icon
          // _controller!.onFeatureTapped.add((point, coordinates, id, layerId, annotation) {
          //   clickedTLayer(layerId);
          // },);

          // Load tricycle icon to list of icons
          final ByteData bytes = await rootBundle.load('assets/img/toda.png');
          final Uint8List list = bytes.buffer.asUint8List();
          _controller!.addImage('toda', list);

          // Load map marker (GPS Location) icon to list of icons
          final ByteData bytes2 = await rootBundle.load('assets/img/mapmarker.png');
          final Uint8List list2 = bytes2.buffer.asUint8List();
          _controller!.addImage('mapmarker', list2);
          _controller!.setSymbolIconAllowOverlap(true);


          // ----------- Add Source & Layer of current location ------------- //
          await _controller?.addSource(
            'source_currentLocation',
            GeojsonSourceProperties(
              data: {
                'type': 'FeatureCollection',
                'features': [
                  {
                    'type': 'Feature',
                    'geometry': {
                      'type': 'Point',
                      'coordinates': [gpsLocation.longitude, gpsLocation.latitude],
                    },
                  },
                ],
              },
            ),
          );

          await _controller?.addLayer(
            'source_currentLocation',
            'layer_currentLocation',
            const SymbolLayerProperties(
              iconImage: 'mapmarker',
              iconSize: 0.4,
            ),
            minzoom: 8,
          );
          // ------------------------------------------------------------------ //
          
        },

        // onMapLongClick adds a point on the map and shows a bottom sheet when user long presses on a spot somewhere in the map
        onMapLongClick: (point, coordinates) async {

          // Remove layer and source of pin if there is one currently on the map
          _controller?.removeLayer('layer_selectedPoint');
          _controller?.removeSource('source_selectedPoint');

          // --- Add source and layer of long press pin --- //
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
              iconImage: 'mapmarker',
              iconSize: 0.4,
            ),
            minzoom: 8,
          );
          // ---------------------------------------------- //
          
          // -- Function that shows destination text box that automatically defaults to coordinates or street name when long pressed, similar to GMaps -- //





          // -------------------------------------------------------------------------------------------------------------------------------------------- //

          // Used to remove long press pin icon from map
          // _controller?.removeLayer('layer_selectedPoint');
          // _controller?.removeSource('source_selectedPoint');

        },
        // onStyleLoadedCallback: addLayers, (COMMENTED OUT UNTIL WE FIGURE OUT IF TO DISPLAY JEEPNEY AND TRICYCLE TERMINALS)

        // Defaults to partial zoom of Pampanga
        initialCameraPosition: const CameraPosition(
          target: LatLng(15.0283971, 120.6292148),
          zoom: 9,
        ),
      );
  }
}