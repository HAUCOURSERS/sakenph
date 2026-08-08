import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:http/http.dart' as http;
import 'package:sakenph/api/database_service.dart';
import 'package:sakenph/api/backend_service.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/computations.dart';
import 'package:sakenph/globals/variables.dart' as global_vars show localIP;
import 'package:sakenph/classes/terminal_class.dart';
import 'package:sakenph/classes/json_response.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_search_details.dart';
import 'dart:math' show min, max, pi, sin, cos, asin, atan2, Point;

import 'package:sakenph/providers/provider_system_vars.dart';
import 'package:sakenph/features/foreground_widget/functions.dart'
    show fetchAndEnrichTodaTerminals, reverseGeocode;

/// Added to import the backend service to use its functions for querying shortest paths and fetching jeepney routes.
import 'package:sakenph/classes/jeepney_route.dart';

/// Holds the view for the map
class MapWidget extends StatefulWidget {
  /// A controller class that provides a public interface to interact with the private `_MapWidget` state.
  ///
  /// The original object is initialized in MapHelperProvider and then passed to the MapWidget constructor. Then upon MapWidget initialization, the pointer towards the
  /// state widget of the MapWidget will be passed towards the MapHelperProvider object in order for the rest of the app to be able to use accessible methods.
  final MapWidgetController? controller; // add this
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

  Future<void> drawPath(
    Map<String, dynamic> pathJSON,
    BuildContext context, [
    String iterationId = "",
  ]) => _state?.drawPath(pathJSON, context, iterationId) ?? Future.value();

  Future<void> drawPathWithOneSourceRef(
    Map<String, dynamic> pathJSON,
    MapHelperProvider mapHelperProvider,
  ) =>
      _state?.drawPathWithOneSourceRef(pathJSON, mapHelperProvider) ??
      Future.value();

  Future<void> flyToBounds(List<LatLng> bounds) =>
      _state?.flyToBounds(bounds) ?? Future.value();

  void clearLayersAndSources() => _state?._clearLayersAndSources();

  Future<void> flyToLoc(LatLng coordinates) =>
      _state?._flyToLoc(coordinates) ?? Future.value();

  void addLayers() => _state?.addLayers();

  Future<void> addUserMarker(LatLng coords, double rotation) =>
      _state?._addUserMarker(coords, rotation) ?? Future.value();

  /// Removes source and layers. During removal, the source and layer
  /// ids are given the prefix of "route-"
  Future<void> removeMarker(String sourceId, String layerId) =>
      _state?._removeMarker(sourceId, layerId) ?? Future.value();

  Future<void> fullRemoveSourceLayer(String sourceId, String layerId) =>
      _state?._fullRemoveSourceLayer(sourceId, layerId) ?? Future.value();

  /// Added to fetch the jeepney routes from the backend.
  Future<void> showJeepneyRoute(JeepneyRoute route) =>
      _state?.showJeepneyRoute(route) ?? Future.value();

  Future<void> hideJeepneyRoute(String routeId) =>
      _state?.hideJeepneyRoute(routeId) ?? Future.value();
}

class _MapWidget extends State<MapWidget> {
  MapLibreMapController? _controller;
  String mapStyle = "";

  // Keeps track of sourceIds and routeIds created from rendering a route
  List<String> routeSourceIds = [];
  List<String> routeLayerIds = [];

  List<Terminal> _todaTerminals = [];

  Future<void> _fullRemoveSourceLayer(String sourceId, String layerId) async {
    if (routeLayerIds.contains(layerId)) {
      routeLayerIds.remove(layerId);
    }
    if (routeSourceIds.contains(sourceId)) {
      routeSourceIds.remove(sourceId);
    }
    _controller?.removeSource(sourceId);
    _controller?.removeLayer(layerId);
  }

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

  /// Removes all existing route sources and layers to avoid duplicates.
  /// If your marker is not getting removed, it was probably not included in this array.
  Future<void> _clearLayersAndSources() async {
    for (String i in routeLayerIds) {
      await _controller?.removeLayer(i);
    }
    routeLayerIds.clear();
    for (String i in routeSourceIds) {
      await _controller?.removeSource(i);
    }
    routeSourceIds.clear();
  }

  Future<void> _removeMarker(String sourceId, String layerId) async {
    _controller?.removeLayer("route-$sourceId");
    _controller?.removeSource("route-$layerId");
  }

  /// Used to render visited edges
  Future<void> drawPathWithOneSourceRef(
    Map<String, dynamic> pathJSON,
    MapHelperProvider mapHelperProvider,
  ) async {
    final Map<String, dynamic> json = pathJSON;
    final RouteResponse multimodalRoute = RouteResponse.fromJson(json);
    await _clearLayersAndSources();
    final List<String> keys = multimodalRoute.routes.keys.toList();

    // Source and Route ID used for drawing only. All drawings fall into this id
    String singularSourceId = "source-for-drawing-only";

    /// The template for the GeoJsonSource's GeoJson value. This will be used
    /// to add more routes in it and update the GeoJsonSource accordingly.
    ///
    /// JSON to add format:
    /// {
    ///   'type': 'Feature',
    ///   'properties': {},
    ///   'geometry': {'type': 'LineString', 'coordinates': coordinates},
    /// },
    ///
    Map<String, dynamic> featureCollectionSetup = {
      'type': 'FeatureCollection',
      'features': [],
    };
    // add source if it doesn't exist
    if (!routeSourceIds.contains(singularSourceId)) {
      await _controller!.addGeoJsonSource(
        singularSourceId,
        featureCollectionSetup,
      );
      routeSourceIds.add(singularSourceId);
    }

    String singularLayerId = "source-for-drawing-only-layer";
    if (!routeLayerIds.contains(singularLayerId)) {
      LineLayerProperties layerStyle = LineLayerProperties(
        lineColor: Colors.blueAccent.toHexStringRGB(),
        lineWidth: 2.0,
      );
      await _controller!.addLineLayer(
        singularSourceId,
        singularLayerId,
        layerStyle,
      );
      routeLayerIds.add(singularLayerId);
    }

    // to count iterations to control geojson update frequency
    int iteration = 0;

    for (String result in keys) {
      for (RouteSegment route in multimodalRoute.routes[result]!) {
        if (route.geometry.length < 2) continue;

        // Drawing slowly is done as an async job with at most 12 milliseconds
        // of delay. This has to be added because users might cancel the viewing for this
        // route, leaving stray nodes to be present and cause crashes.
        if (mapHelperProvider.shouldStopDrawing == true) return;

        // Add a line feature to the setup
        List<dynamic> featuresList = featureCollectionSetup['features'];
        featuresList.add({
          'type': 'Feature',
          'properties': {},
          'geometry': {'type': 'LineString', 'coordinates': route.geometry},
        });

        if (iteration % 4 == 0) {
          await _controller!.setGeoJsonSource(
            singularSourceId,
            featureCollectionSetup,
          );
        }

        iteration++;

        //await Future.delayed(Duration(milliseconds: 1));
      }
    }
    await _controller!.setGeoJsonSource(
      singularSourceId,
      featureCollectionSetup,
    );

    // Create markers for the start and end points of the route
    String fromLocId = "route-fromloc";
    String toLocId = "route-toloc";
    String toLocIdCircle = "route-toloc-circle";
    LatLng? fromLocDetails = mapHelperProvider.getSelectedFromLocationDetails;
    await _addMarker(fromLocDetails!, "mapmarker_green", fromLocId);

    LatLng? toLocDetails = mapHelperProvider.getSelectedToLocationDetails;
    await _addMarker(toLocDetails!, "mapmarker_red", toLocId);

    await _createCircle(
      center: toLocDetails,
      sourceId: toLocIdCircle,
      layerId: toLocIdCircle,
      radius: 20,
      fillColor: '#3b82f6',
      fillOpacity: 0.25,
      borderColor: '#2563eb',
      borderWidth: 2.0,
    );
    print("[TEMP] DONE DRAWING");
  }

  /// Uses json value obtained from backend and draws the path
  Future<void> drawPath(
    Map<String, dynamic> pathJSON,
    BuildContext context, [
    String iterationId = "",
  ]) async {
    print("CALLED: ITERATION ID: $iterationId");
    MapHelperProvider mapHelperProvider = context.read<MapHelperProvider>();
    final Map<String, dynamic> json = pathJSON;
    final RouteResponse multimodalRoute = RouteResponse.fromJson(json);

    // Removes all existing route sources and layers to avoid duplicates
    await _clearLayersAndSources();
    final List<String> keys = multimodalRoute.routes.keys.toList();

    int sourceLayerId = 1;
    for (String result in keys) {
      for (RouteSegment route in multimodalRoute.routes[result]!) {
        if (route.geometry.length < 2) {
          continue;
        }

        // Drawing slowly is done as an async job with at most 12 milliseconds
        // of delay. This has to be added because users might cancel the viewing for this
        // route, leaving stray nodes to be present and cause crashes.
        if (mapHelperProvider.shouldStopDrawing == true) return;

        // init route source layer ids
        String sourceId = "${iterationId}route-$sourceLayerId";
        routeSourceIds.add(sourceId);
        String layerId = "${iterationId}route-$sourceLayerId";
        routeLayerIds.add(layerId);

        // declare line style properties
        LineLayerProperties layerStyle;
        LineLayerProperties? outlineLayerStyle;
        if (route.mode.type == 'walk') {
          layerStyle = LineLayerProperties(
            lineColor: route.mode.details.color,
            lineWidth: 3.0,
            lineDasharray: [1, 1],
          );
        } else {
          // routes such as jeepney routes will have borders in it
          layerStyle = LineLayerProperties(
            lineColor: route.mode.details.color,
            lineWidth: 2.0,
          );
          outlineLayerStyle = LineLayerProperties(
            lineColor: darkenHex(route.mode.details.color),
            lineWidth: 4.0,
          );
        }

        await _controller!.addGeoJsonSource(
          sourceId,
          _buildLineGeoJson([route.geometry.first]),
        );

        // If route isn't walking, prepare the source and layer for the outline drawing
        if (route.mode.type != 'walk') {
          String sourceOutline = "$sourceId-outline";
          String layerOutline = "$layerId-outline";

          await _controller!.addGeoJsonSource(
            sourceOutline,
            _buildLineGeoJson([route.geometry.first]),
          );

          await _controller!.addLineLayer(
            sourceOutline,
            layerOutline,
            outlineLayerStyle!,
          );

          routeSourceIds.add(sourceOutline);
          routeLayerIds.add(layerOutline);
        }

        await _controller!.addLineLayer(sourceId, layerId, layerStyle);

        if (route.mode.type != 'walk') {
          await _animateLineSource(
            sourceId: sourceId,
            geometry: route.geometry,
            mode: "non-walking",
            totalDurationMs: 200,
          );
        } else {
          await _animateLineSource(
            sourceId: sourceId,
            geometry: route.geometry,
            mode: "walking",
            totalDurationMs: 200,
          );
        }

        sourceLayerId++;
      }
    }

    // Create markers for the start and end points of the route
    sourceLayerId += 1;
    LatLng? fromLocDetails = mapHelperProvider.getSelectedFromLocationDetails;
    await _addMarker(
      fromLocDetails!,
      "mapmarker_green",
      iterationId + sourceLayerId.toString(),
    );

    sourceLayerId += 1;
    LatLng? toLocDetails = mapHelperProvider.getSelectedToLocationDetails;
    await _addMarker(
      toLocDetails!,
      "mapmarker_red",
      iterationId + sourceLayerId.toString(),
    );

    await _createCircle(
      center: toLocDetails,
      sourceId: "${iterationId}source_circle_ToLoc",
      layerId: "${iterationId}layer_circle_ToLoc",
      radius: 20,
      fillColor: '#3b82f6',
      fillOpacity: 0.25,
      borderColor: '#2563eb',
      borderWidth: 2.0,
    );
  }

  /// For the mode argument, the accepted String values is "walking" and "non-walking"
  Future<void> _animateLineSource({
    required String sourceId,
    required List<List<double>> geometry,
    required int totalDurationMs,
    required String mode,
  }) async {
    if (geometry.length < 2) return;

    const targetFps = 30;
    final frameIntervalMs = (1000 / targetFps).round();
    final totalFrames = (totalDurationMs / frameIntervalMs).ceil();
    final pointsPerFrame = (geometry.length / totalFrames).ceil().clamp(
      1,
      geometry.length,
    );

    final List<List<double>> visibleGeometry = [geometry.first];
    int index = 1;

    while (index < geometry.length) {
      final end = (index + pointsPerFrame).clamp(0, geometry.length);
      visibleGeometry.addAll(geometry.sublist(index, end));
      index = end;

      final geoJson = _buildLineGeoJson(visibleGeometry);
      if (mode == "walking") {
        await _controller!.setGeoJsonSource(sourceId, geoJson);
      } else if (mode == "non-walking") {
        await _controller!.setGeoJsonSource(sourceId, geoJson);
        await _controller!.setGeoJsonSource("$sourceId-outline", geoJson);
      }

      await Future.delayed(Duration(milliseconds: frameIntervalMs));
    }
  }

  Future<void> _animateLinesAsOneSource({
    required String sourceId,
    required List<List<List<double>>> allGeometries, // list of routes/edges
    required int totalDurationMs,
  }) async {
    const targetFps = 30;
    final frameIntervalMs = (1000 / targetFps).round();
    final totalFrames = (totalDurationMs / frameIntervalMs).ceil();

    final cursors = List<int>.filled(allGeometries.length, 1);
    final visible = allGeometries
        .map((g) => g.isNotEmpty ? [g.first] : <List<double>>[])
        .toList();

    final pointsPerFrame = List<int>.generate(allGeometries.length, (i) {
      final len = allGeometries[i].length;
      return len < 2 ? 0 : (len / totalFrames).ceil().clamp(1, len);
    });

    for (int frame = 0; frame < totalFrames; frame++) {
      bool anyUpdated = false;

      for (int i = 0; i < allGeometries.length; i++) {
        final geometry = allGeometries[i];
        if (geometry.length < 2) continue;
        if (cursors[i] >= geometry.length) continue;

        final end = (cursors[i] + pointsPerFrame[i]).clamp(0, geometry.length);
        visible[i].addAll(geometry.sublist(cursors[i], end));
        cursors[i] = end;
        anyUpdated = true;
      }

      final features = visible
          .where((v) => v.length >= 2)
          .map(
            (v) => {
              'type': 'Feature',
              'geometry': {'type': 'LineString', 'coordinates': v},
              'properties': {},
            },
          )
          .toList();

      await _controller!.setGeoJsonSource(sourceId, {
        'type': 'FeatureCollection',
        'features': features,
      });

      if (!anyUpdated) break;
      await Future.delayed(Duration(milliseconds: frameIntervalMs));
    }
  }

  /// Builder of the edge line between 2 points
  Map<String, dynamic> _buildLineGeoJson(List<List<double>> coordinates) {
    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {},
          'geometry': {'type': 'LineString', 'coordinates': coordinates},
        },
      ],
    };
  }

  Future<void> _addMarker(
    LatLng coords,
    String imageId,
    String markerId,
  ) async {
    final String sourceId = 'source_$markerId';
    final String layerId = 'layer_$markerId';

    routeSourceIds.add(sourceId);
    routeLayerIds.add(layerId);

    await _controller!.addGeoJsonSource(sourceId, {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [coords.longitude, coords.latitude],
          },
          'properties': {},
        },
      ],
    });

    await _controller!.addSymbolLayer(
      sourceId,
      layerId,
      SymbolLayerProperties(
        iconImage: imageId, // must match the ID used in addImage()
        iconSize: 0.2,
        iconAllowOverlap: true,
        iconAnchor: 'bottom', // tip of pin touches the coordinate
      ),
    );
  }

  Future<bool> _sourceExists(String sourceId) async {
    final ids = await _controller?.getSourceIds() ?? [];
    return ids.contains(sourceId);
  }

  Future<bool> _layerExists(String layerId) async {
    final ids = await _controller?.getLayerIds() ?? [];
    return ids.contains(layerId);
  }

  /// Added for loading jeepney routes from the backend.
  /// Generates a unique source ID for a jeepney route based on its route ID.
  String _jeepneyRouteSourceId(String routeId) {
    return 'jeepney-route-source-$routeId';
  }

  String _jeepneyRouteLayerId(String routeId) {
    return 'jeepney-route-layer-$routeId';
  }

  /// Draws one jeepney route line on the map.
  Future<void> showJeepneyRoute(JeepneyRoute route) async {
    if (_controller == null) return;

    final sourceId = _jeepneyRouteSourceId(route.id);
    final layerId = _jeepneyRouteLayerId(route.id);

    // Already drawn or currently being drawn by a concurrent call.
    if (jeepneyRouteSourceIds.contains(sourceId)) return;
    if (!_jeepneyRouteAddsInProgress.add(sourceId)) return;

    try {
      if (await _sourceExists(sourceId)) return;

      await _controller!.addSource(
        sourceId,
        GeojsonSourceProperties(data: route.geojson),
      );

      await _controller!.addLineLayer(
        sourceId,
        layerId,
        LineLayerProperties(
          lineColor: route.color,
          lineWidth: 3.5,
          lineOpacity: 0.85,
        ),
      );

      jeepneyRouteSourceIds.add(sourceId);
      jeepneyRouteLayerIds.add(layerId);
    } catch (_) {
      // Swallow duplicate add errors from rapid repeated calls.
    } finally {
      _jeepneyRouteAddsInProgress.remove(sourceId);
    }
  }

  /// Removes one jeepney route line from the map.
  Future<void> hideJeepneyRoute(String routeId) async {
    if (_controller == null) return;

    final sourceId = _jeepneyRouteSourceId(routeId);
    final layerId = _jeepneyRouteLayerId(routeId);

    try {
      await _controller!.removeLayer(layerId);
    } catch (_) {
      // Layer may already be gone after rapid repeated calls.
    }

    try {
      await _controller!.removeSource(sourceId);
    } catch (_) {
      // Source may already be gone after rapid repeated calls.
    }

    jeepneyRouteLayerIds.remove(layerId);
    jeepneyRouteSourceIds.remove(sourceId);
  }

  final Set<String> jeepneyRouteSourceIds = {};
  final Set<String> jeepneyRouteLayerIds = {};
  final Set<String> _jeepneyRouteAddsInProgress = {};

  Future<void> _addUserMarker(LatLng coords, double rotation) async {
    final String sourceId = 'route-source_user_marker';
    final String layerId = 'route-layer_user_marker';

    bool ifSourceExists = await _sourceExists(sourceId);
    bool ifLayerExists = await _layerExists(layerId);

    if (ifSourceExists && ifLayerExists) {
      // ✅ Just update the source — layer will auto-read rotation via expression
      await _controller!.setGeoJsonSource(
        sourceId,
        _buildGeoJson(coords, rotation),
      );
    } else {
      await _controller?.removeLayer(layerId);
      await _controller?.removeSource(sourceId);

      routeSourceIds.add(sourceId);
      routeLayerIds.add(layerId);

      // ✅ Include rotation in properties from the start
      await _controller!.addGeoJsonSource(
        sourceId,
        _buildGeoJson(coords, rotation),
      );

      await _controller!.addSymbolLayer(
        sourceId,
        layerId,
        SymbolLayerProperties(
          iconImage: "user_marker",
          iconSize: 0.35,
          iconAllowOverlap: true,
          iconAnchor: 'bottom',
          iconRotate: [
            'get',
            'rotation',
          ], // ✅ bind to property, not static value
          iconRotationAlignment: "map",
        ),
      );
    }
  }

  // ✅ Single reusable GeoJSON builder
  Map<String, dynamic> _buildGeoJson(LatLng coords, double rotation) {
    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [coords.longitude, coords.latitude],
          },
          'properties': {
            'rotation': rotation, // ✅ always included
          },
        },
      ],
    };
  }

  List<List<List<double>>> _buildCirclePolygon(
    LatLng center,
    double radiusMeters, {
    int steps = 64,
  }) {
    const double earthRadius = 6371000.0;
    final double lat = center.latitude * pi / 180.0;
    final double lon = center.longitude * pi / 180.0;
    final double angularRadius = radiusMeters / earthRadius;

    final List<List<double>> ring = [];
    for (int i = 0; i <= steps; i++) {
      final double bearing = (i / steps) * 2 * pi;
      final double lat2 = asin(
        sin(lat) * cos(angularRadius) +
            cos(lat) * sin(angularRadius) * cos(bearing),
      );
      final double lon2 =
          lon +
          atan2(
            sin(bearing) * sin(angularRadius) * cos(lat),
            cos(angularRadius) - sin(lat) * sin(lat2),
          );

      ring.add([lon2 * 180.0 / pi, lat2 * 180.0 / pi]);
    }

    if (ring.isNotEmpty) {
      final first = ring.first;
      final last = ring.last;
      if (first[0] != last[0] || first[1] != last[1]) {
        ring.add(first.toList());
      }
    }

    return [ring];
  }

  Future<void> _createCircle({
    required LatLng center,
    required String sourceId,
    required String layerId,
    double radius = 20,
    String fillColor = '#3b82f6',
    double fillOpacity = 0.25,
    String borderColor = '#2563eb',
    double borderWidth = 2.0,
  }) async {
    if (_controller == null) return;

    final String outlineLayerId = '$layerId-outline';

    await _controller?.removeLayer(layerId);
    await _controller?.removeLayer(outlineLayerId);
    await _controller?.removeSource(sourceId);

    routeSourceIds.add(sourceId);
    routeLayerIds.add(layerId);
    routeLayerIds.add(outlineLayerId);

    await _controller?.addSource(
      sourceId,
      GeojsonSourceProperties(
        data: {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'geometry': {
                'type': 'Polygon',
                'coordinates': _buildCirclePolygon(center, radius),
              },
              'properties': {},
            },
          ],
        },
      ),
    );

    await _controller?.addFillLayer(
      sourceId,
      layerId,
      FillLayerProperties(fillColor: fillColor, fillOpacity: fillOpacity),
    );

    await _controller?.addLineLayer(
      sourceId,
      outlineLayerId,
      LineLayerProperties(
        lineColor: borderColor,
        lineWidth: borderWidth,
        lineOpacity: 1.0,
      ),
    );
  }

  Future<void> _flyToLoc(LatLng coordinates) async {
    print("TEMP: $coordinates");
    await _controller!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(coordinates.latitude, coordinates.longitude),
        15.0,
      ),
    );
  }

  Future<void> _loadTodaTerminals() async {
    try {
      // Enrich terminals with barangay where possible for better UX
      _todaTerminals = await fetchAndEnrichTodaTerminals();
      await addTodaLayers();
    } catch (e) {
      print('[TEMP] Failed to load TODA terminals: $e');
    }
  }

  void _showTerminalDetails(BuildContext context, Terminal terminal) {
    // Use a persistent bottom sheet so the rest of the UI remains interactive
    final futureLocationLabel = terminal.barangay != null
        ? Future.value(terminal.barangay ?? 'Unknown location')
        : reverseGeocode(
            latitude: terminal.latitude,
            longitude: terminal.longitude,
          );

    late PersistentBottomSheetController controller;
    controller = Scaffold.of(context).showBottomSheet((ctx) {
      final theme = Theme.of(ctx);
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.viewPaddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    terminal.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'TODA',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FutureBuilder<String>(
              future: futureLocationLabel,
              builder: (ctx2, snapshot) {
                final label =
                    snapshot.connectionState == ConnectionState.waiting
                    ? 'Resolving barangay...'
                    : snapshot.hasError
                    ? 'Unknown location'
                    : snapshot.data ?? 'Unknown location';
                return Row(
                  children: [
                    Icon(
                      Icons.place,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(label, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => controller.close(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      );
    }, backgroundColor: Colors.transparent);
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
    for (Terminal t in _todaTerminals) {
      final sourceId = 'toda_source_${t.id}';
      final layerId = 'toda_layer_${t.id}';

      await _controller?.addSource(
        sourceId,
        GeojsonSourceProperties(
          data: {
            'type': 'FeatureCollection',
            'features': [
              {
                'type': 'Feature',
                'properties': {'name': t.name},
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
        sourceId,
        layerId,
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

  Future<void> _addImageToController(
    String imgDirectory,
    String imgID,
    bool symbolIconAllowOverlap,
  ) async {
    final ByteData bytes = await rootBundle.load(imgDirectory);
    final Uint8List list = bytes.buffer.asUint8List();
    _controller!.addImage(imgID, list);
    _controller!.setSymbolIconAllowOverlap(symbolIconAllowOverlap);
  }

  @override
  Widget build(BuildContext context) {
    SystemVariablesProvider systemVariablesProvider = context
        .read<SystemVariablesProvider>();
    SearchDetailsProvider searchDetailsProvider = context
        .read<SearchDetailsProvider>();

    return MapLibreMap(
      styleString: mapStyle,

      compassEnabled: true,
      compassViewPosition: CompassViewPosition.bottomRight,
      compassViewMargins: Point(16, 40),

      onMapCreated: (c) async {
        // Gets point of current location of GPS
        //Position gpsLocation = await determinePosition();

        _controller = c;

        // Load jeepney routes from backend
        await context.read<MapHelperProvider>().loadJeepneyRoutes();

        // Load tricycle icon to list of icons
        _addImageToController('assets/img/toda.png', 'toda', false);

        _controller!.onFeatureTapped.add((
          point,
          coordinates,
          id,
          layerId,
          annotation,
        ) async {
          if (layerId.toString().startsWith('toda_layer_')) {
            final selected = _todaTerminals.firstWhere(
              (terminal) => 'toda_layer_${terminal.id}' == layerId,
              orElse: () => Terminal(
                id: -1,
                name: 'Unknown Terminal',
                longitude: 0,
                latitude: 0,
              ),
            );
            if (selected.id != -1) {
              // Animate camera to the terminal location before showing details
              try {
                await _flyToLoc(LatLng(selected.latitude, selected.longitude));
              } catch (e) {
                // If animation fails, still show details
                print('[TODA] Failed to fly to terminal: $e');
              }

              _showTerminalDetails(context, selected);
            }
          }
        });

        await _loadTodaTerminals();

        // Load map marker (GPS Location) icon to list of icons
        _addImageToController('assets/img/mapmarker.png', 'mapmarker', true);
        _addImageToController(
          'assets/img/mapmarker_red.png',
          'mapmarker_red',
          true,
        );
        _addImageToController(
          'assets/img/mapmarker_green.png',
          'mapmarker_green',
          true,
        );
        _addImageToController(
          'assets/img/user_marker.png',
          'user_marker',
          true,
        );

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

      onMapClick: (point, coordinates) {},

      onMapLongClick: (point, coordinates) async {
        print("long click trigger");
        SystemState currentState = systemVariablesProvider.appCurrentState;

        // Disable this behavior if user is in these systemstates.
        if (currentState == SystemState.peekAtRoute ||
            currentState == SystemState.isCurrentlyTravelling) {
          return;
        }

        // Remove layer and source of pin if there is one currently on the map
        _controller?.removeLayer('layer_selectedPoint');
        _controller?.removeSource('source_selectedPoint');

        // remove and add the layer and source ids of the marker for proper practice
        if (routeLayerIds.contains('layer_selectedPoint')) {
          routeLayerIds.remove('layer_selectedPoint');
        }
        if (routeLayerIds.contains('source_selectedPoint')) {
          routeLayerIds.remove('source_selectedPoint');
        }

        routeLayerIds.add('layer_selectedPoint');
        routeSourceIds.add('source_selectedPoint');

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
                    'coordinates': [
                      coordinates.longitude,
                      coordinates.latitude,
                    ],
                  },
                },
              ],
            },
          ),
        );

        await _controller?.addLayer(
          'source_selectedPoint',
          'layer_selectedPoint',
          const SymbolLayerProperties(iconImage: 'mapmarker', iconSize: 0.4),
          minzoom: 8,
        );

        searchDetailsProvider.setLongPressedLocation = coordinates;

        // change app state
        systemVariablesProvider.setAppCurrentState =
            SystemState.confirmingLocationSelection;
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
