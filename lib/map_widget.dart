import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:http/http.dart' as http;
import 'package:sakenph/api/database_service.dart';
import 'package:sakenph/globals/variables.dart' as global_vars show localIP;
import 'package:sakenph/providers/provider_mapwidget_handler.dart';
import 'package:sakenph/classes/terminal_class.dart';
import 'package:sakenph/classes/json_response.dart';
import 'package:provider/provider.dart';
import 'dart:math' show min, max;

/// Holds the view for the map
class MapWidget extends StatefulWidget {
  final MapWidgetController? controller; // add thi
  const MapWidget({super.key, required this.controller});

  @override
  State<MapWidget> createState() => _MapWidget();
}

/// Means to access the MapWidget state's functions properly.
class MapWidgetController {
  _MapWidget? _state;

  void _attach(_MapWidget state) => _state = state;
  void _detach() => _state = null;

  Future<void> shortestPath(LatLng origin, LatLng dest) =>
      _state?.shortestPath(origin, dest) ?? Future.value();

  Future<void> drawPath(Map<String, dynamic> pathJSON) =>
      _state?.drawPath(pathJSON) ?? Future.value();

  Future<void> flyToBounds(List<LatLng> bounds) =>
      _state?.flyToBounds(bounds) ?? Future.value();

  void addLayers() => _state?.addLayers();
}

class _MapWidget extends State<MapWidget> {
  MapLibreMapController? _controller;
  String mapStyle = "";

  // Keeps track of sourceIds and routeIds created from rendering a route
  List<String> routeSourceIds = [];
  List<String> routeLayerIds = [];

  // Loads custom map style from assets based on Stadia Map's OSM Bright style
  Future<void> _loadStyle() async {
    final json = await rootBundle.loadString(
      'assets/map_styles/osm_bright2.json',
    );

    setState(() => mapStyle = json);
  }

  @override
  void initState() {
    super.initState();
    _loadStyle();
    widget.controller?._attach(this);
    //addLayers();
  }

  @override
  void dispose() {
    widget.controller?._detach(); // detach on dispose
    super.dispose();
  }

  /// Uses json value obtained from backend and draws the path
  Future<void> drawPath(Map<String, dynamic> pathJSON) async {
    print("[TEMP] DRAWPATH TRIGGERED!");
    final Map<String, dynamic> json = pathJSON;
    final RouteResponse multimodalRoute = RouteResponse.fromJson(json);

    // Removes all existing route sources and layers to avoid duplicates
    for (String i in routeLayerIds) {
      _controller?.removeLayer(i);
    }
    routeLayerIds.clear();
    for (String i in routeSourceIds) {
      _controller?.removeSource(i);
    }
    routeSourceIds.clear();
    final List<String> keys = multimodalRoute.routes.keys.toList();

    int sourceLayerId = 1;
    for (String result in keys) {
      for (RouteSegment route in multimodalRoute.routes[result]!) {
        String sourceId = "route-$sourceLayerId";
        routeSourceIds.add(sourceId);
        String layerId = "route-$sourceLayerId";
        routeLayerIds.add(layerId);

        LineLayerProperties layerStyle;
        if (route.mode.type == 'walk') {
          // Blue dotted lines to indicate walking route
          layerStyle = LineLayerProperties(
            lineColor: route.mode.details.color,
            lineWidth: 3.0,
            lineDasharray: [1, 1],
          );
        } else {
          // Solid lines to indicate vehicle route
          layerStyle = LineLayerProperties(
            lineColor: route.mode.details.color,
            lineWidth: 3.0,
          );
        }

        // Defines the specific geometry of the route line
        // route.geometry is a list of coordinate pairs that form a line
        await _controller!.addGeoJsonSource(sourceId, {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {},
              'geometry': {'type': 'LineString', 'coordinates': route.geometry},
            },
          ],
        });

        // Defines the style of the line
        await _controller!.addLineLayer(sourceId, layerId, layerStyle);

        sourceLayerId++;
      }
    }
  }

  // Adjusts camera based on coordinates
  Future<void> flyToBounds(List<LatLng> coordinates) async {
    if (coordinates.isEmpty) return;

    // Find the bounding box
    double minLat = coordinates.map((c) => c.latitude).reduce(min);
    double maxLat = coordinates.map((c) => c.latitude).reduce(max);
    double minLng = coordinates.map((c) => c.longitude).reduce(min);
    double maxLng = coordinates.map((c) => c.longitude).reduce(max);

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await _controller?.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        left: 120,
        top: 50,
        right: 120,
        bottom: 250,
      ),
    );
  }

  // UNUSED FUNCTION FOR NOW: used when clicked on a TODA Terminal icon
  Future<void> clickedTLayer(String layerId) async {
    print("In function:");
    if (context.mounted) {
      print("Context is mounted");

      int terminalId = int.parse(layerId.replaceAll('layer_', ""));
      final Terminal tappedTerminal = await DatabaseService().getTerminalById(
        terminalId,
      );
      print("Terminal retrieved");

      final sheetController = Scaffold.of(context).showBottomSheet((context) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: const Color.fromARGB(255, 227, 241, 253),
          ),
          width: MediaQuery.of(context).size.width,
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [Text('Jeepney Terminal'), Text(tappedTerminal.name)],
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: 320,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  padding: EdgeInsets.all(10),
                  child: Text(
                    "Add Terminal",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
              ),
            ],
          ),
        );
      });
      sheetController.closed.then((E) {
        _controller?.removeLayer('layer_selectedPoint');
        _controller?.removeSource('source_selectedPoint');
      });
    }
  }

  /// Function used. (Currently unused?)
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
        const SymbolLayerProperties(iconImage: 'toda', iconSize: 0.25),
        minzoom: 12,
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
        const SymbolLayerProperties(iconImage: 'bus', iconSize: 1.5),
        minzoom: 8,
      );
    }
  }

  // Function that calls result from shortestPathTest() in backend and renders the path
  // TO DO:
  // shortestPath() should also have src parameter, it should be retrieved from a separate coordinates value from the source/dest TextBox
  //
  // UNUSED FUNCTION FOR NOW: this is obsolete since parts of this function are to be used separately
  Future<void> shortestPath(LatLng origin, LatLng dest) async {
    // TODO: Remove this print statement once done checking if the function is working as intended
    print("[TEMP] shortestPath() Method Called!");
    String localIp = global_vars.localIP;
    // Position gpsLocation = await determinePosition();

    print(
      'http://$localIp:8000/k_shortest_paths?src=${origin.latitude},${origin.longitude}&dest=${dest.latitude},${dest.longitude}',
    );
    final response = await http.get(
      Uri.parse(
        'http://$localIp:8000/k_shortest_paths?src=${origin.latitude},${origin.longitude}&dest=${dest.latitude},${dest.longitude}',
      ),
    );

    if (response.statusCode == 200) {
      print("[TEMP] Recieved backend response");
      final Map<String, dynamic> json = jsonDecode(response.body);
      final RouteResponse multimodalRoute = RouteResponse.fromJson(json);

      // Removes all existing route sources and layers to avoid duplicates
      for (String i in routeLayerIds) {
        _controller?.removeLayer(i);
      }
      routeLayerIds.clear();
      for (String i in routeSourceIds) {
        _controller?.removeSource(i);
      }
      routeSourceIds.clear();
      final List<String> keys = multimodalRoute.routes.keys.toList();

      int sourceLayerId = 1;
      for (String result in keys) {
        for (RouteSegment route in multimodalRoute.routes[result]!) {
          String sourceId = "route-$sourceLayerId";
          routeSourceIds.add(sourceId);
          String layerId = "route-$sourceLayerId";
          routeLayerIds.add(layerId);

          LineLayerProperties layerStyle;
          if (route.mode.type == 'walk') {
            // Blue dotted lines to indicate walking route
            layerStyle = LineLayerProperties(
              lineColor: route.mode.details.color,
              lineWidth: 3.0,
              lineDasharray: [1, 1],
            );
          } else {
            // Solid lines to indicate vehicle route
            layerStyle = LineLayerProperties(
              lineColor: route.mode.details.color,
              lineWidth: 3.0,
            );
          }

          // Defines the specific geometry of the route line
          // route.geometry is a list of coordinate pairs that form a line
          await _controller!.addGeoJsonSource(sourceId, {
            'type': 'FeatureCollection',
            'features': [
              {
                'type': 'Feature',
                'properties': {},
                'geometry': {
                  'type': 'LineString',
                  'coordinates': route.geometry,
                },
              },
            ],
          });

          // Defines the style of the line
          await _controller!.addLineLayer(sourceId, layerId, layerStyle);

          sourceLayerId++;
        }
      }

      // // Renders a separate and preferably distinguishable line for each route
      // int sourceLayerId = 1;
      // for (RouteSegment route in multimodalRoute.route) {
      //   String sourceId = "route-$sourceLayerId";
      //   routeSourceIds.add(sourceId);
      //   String layerId = "route-$sourceLayerId";
      //   routeLayerIds.add(layerId);

      //   LineLayerProperties layerStyle;
      //   if (route.mode.type == 'walk') {
      //     // Blue dotted lines to indicate walking route
      //     layerStyle = LineLayerProperties(
      //       lineColor: route.mode.details.color,
      //       lineWidth: 3.0,
      //       lineDasharray: [1, 1],
      //     );
      //   } else {
      //     // Solid lines to indicate vehicle route
      //     layerStyle = LineLayerProperties(
      //       lineColor: route.mode.details.color,
      //       lineWidth: 3.0,
      //     );
      //   }

      //   // Defines the specific geometry of the route line
      //   // route.geometry is a list of coordinate pairs that form a line
      //   await _controller!.addGeoJsonSource(sourceId, {
      //     'type': 'FeatureCollection',
      //     'features': [
      //       {
      //         'type': 'Feature',
      //         'properties': {},
      //         'geometry': {'type': 'LineString', 'coordinates': route.geometry},
      //       },
      //     ],
      //   });

      //   // Defines the style of the line
      //   await _controller!.addLineLayer(sourceId, layerId, layerStyle);

      //   sourceLayerId++;
      // }
    }
  }

  // Uses geolocator package to get current location
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
        'Location permissions are permanently denied, we cannot request permissions.',
      );
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
        //Position gpsLocation = await determinePosition();

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
        final ByteData bytes2 = await rootBundle.load(
          'assets/img/mapmarker.png',
        );
        final Uint8List list2 = bytes2.buffer.asUint8List();
        _controller!.addImage('mapmarker', list2);
        _controller!.setSymbolIconAllowOverlap(true);

        // ----------- Add Source & Layer of current location ------------- //
        /*
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
                    'coordinates': [
                      gpsLocation.longitude,
                      gpsLocation.latitude,
                    ],
                  },
                },
              ],
            },
          ),
        );
        */

        await _controller?.addLayer(
          'source_currentLocation',
          'layer_currentLocation',
          const SymbolLayerProperties(iconImage: 'mapmarker', iconSize: 0.4),
          minzoom: 8,
        );
        // ------------------------------------------------------------------ //
      },

      onMapLongClick: (point, coordinates) async {
        // Calculates and displays shortest path to point where user long presses
        shortestPath(
          context.read<MapWidgetHandlerProvider>().fromLoc!,
          coordinates,
        );

        // Remove layer and source of pin if there is one currently on the map
        _controller?.removeLayer('layer_selectedPoint');
        _controller?.removeSource('source_selectedPoint');

        // --- Add source and layer of long press pin --- //
        // await _controller?.addSource(
        //   'source_selectedPoint',
        //   GeojsonSourceProperties(
        //     data: {
        //       'type': 'FeatureCollection',
        //       'features': [
        //         {
        //           'type': 'Feature',
        //           'geometry': {
        //             'type': 'Point',
        //             'coordinates': [coordinates.longitude, coordinates.latitude],
        //           },
        //         },
        //       ],
        //     },
        //   ),
        // );

        // await _controller?.addLayer(
        //   'source_selectedPoint',
        //   'layer_selectedPoint',
        //   const SymbolLayerProperties(
        //     iconImage: 'mapmarker',
        //     iconSize: 0.4,
        //   ),
        //   minzoom: 8,
        // );

        // ---------------------------------------------- //

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
