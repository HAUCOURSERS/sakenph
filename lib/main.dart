// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:maplibre_gl/maplibre_gl.dart';

// class SimpleMapPage extends StatefulWidget {
//   const SimpleMapPage({super.key});
//   @override
//   State<SimpleMapPage> createState() => _SimpleMapPageState();
// }

// class _SimpleMapPageState extends State<SimpleMapPage> {
//   final _controllerCompleter = Completer<MapLibreMapController>();
//   bool _styleLoaded = false;

//   static const _initial = CameraPosition(target: LatLng(0, 0), zoom: 2);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('MapLibre Quick Start')),
//       floatingActionButton: _styleLoaded
//           ? FloatingActionButton.small(
//               onPressed: _goHome,
//               child: const Icon(Icons.explore),
//             )
//           : null,
//       body: MapLibreMap(
//         initialCameraPosition: _initial,
//         onMapCreated: (c) => _controllerCompleter.complete(c),
//         onStyleLoadedCallback: () => setState(() => _styleLoaded = true),
//       ),
//     );
//   }

//   Future<void> _goHome() async { 
//     final c = await _controllerCompleter.future;
//     await c.animateCamera(CameraUpdate.newCameraPosition(_initial));
//   }

import 'package:flutter/material.dart';
import 'package:sakenph/auth_gate.dart';
import 'package:sakenph/login_register.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tfycptprhagrgpxccjiy.supabase.co',
    anonKey: 'sb_publishable_M6rcjMdAMWceiBpMkQQOVg_ejVFeKK7'
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'saken.ph',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      home: const AuthGate(),
    );
  }
}