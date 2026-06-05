import 'package:flutter/material.dart';
import 'package:sakenph/features/background_widget/widgets.dart';
import 'package:sakenph/features/foreground_widget/functions.dart'
    show fetchData, handleLocationPermission, searchPlaces;
import 'package:sakenph/features/foreground_widget/widgets.dart';
import 'package:sakenph/map_widget.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

/// Used to improve reusability of the GestureDetector builder
enum _LocationSource { FROM, TO }

class _HomePage extends State<HomePage> {
  late Future<Map<dynamic, dynamic>> json;

  @override
  void initState() {
    super.initState();
    json = fetchData();
  }

  /*
  Future<Position> getUserLoc() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return position;
  }
  */

  @override
  Widget build(BuildContext context) {
    handleLocationPermission(context);
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          /// Renders the map
          MapWidget(),

          /// Renders the background widget where other features and widgets
          /// could appear based on the current logic
          BackgroundWidget(),

          /// Renders widgets that are intended to only show up within the safe
          /// area and to show up above the other widgets
          ForegroundWidget(),
          //SafeArea(
          //  child: Stack(children: [ForegroundWidget()]),
          //),
        ],
      ),
    );
  }
}
