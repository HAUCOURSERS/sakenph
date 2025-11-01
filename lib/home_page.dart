

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sakenph/auth_service.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'dart:io';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  MapLibreMapController? _controller;
  String mapStyle = "";

  void loadMapStyle() async {
    print("JUST TO MAKE SURE");
    final osmBrightJson = await rootBundle.loadString('assets/map_styles/osm_bright.json');

    mapStyle = osmBrightJson;
    print(jsonDecode(osmBrightJson));
    print(osmBrightJson);
  }

      @override
    void initState() {
      loadMapStyle();
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
        styleString: 'assets/map_styles/osm_bright.json',
        onMapCreated: (c) => _controller = c,
        initialCameraPosition: const CameraPosition(
          target: LatLng(0, 0),
          zoom: 1.0,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final c = _controller;
          if (c == null) return;
          await c.animateCamera(
            CameraUpdate.newCameraPosition(
              const CameraPosition(target: LatLng(15, 121), zoom: 9),
            ),
          );
        },
        child: const Icon(Icons.flight),
      ),
    );
  }
}