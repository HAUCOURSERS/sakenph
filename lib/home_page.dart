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

  /// Whether to display the dropdown visual
  // ignore: non_constant_identifier_names
  bool _showDropdownFor_fromLocation = false;
  // ignore: non_constant_identifier_names
  bool _showDropdownFor_toLocation = false;
  bool _isLoading = true;

  /// Calls Nominatim Public API to do searches. This function has to be inside of this
  /// state class to perform setState() calls.
  void querySearchPlaces(String query) async {
    print("[TEMP] searchPlaces() called!");

    setState(() {
      _isLoading = true;
    });

    final results = await searchPlaces(query);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    json = fetchData();
  }

  Future<Position> getUserLoc() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return position;
  }
  // not needed atm
  /*
  GestureDetector suggestionGestureBuilder(int index, _LocationSource source) {
    final place = _toLocationResults[index];
    return GestureDetector(
      onTap: () {
        final lat = place.lat;
        final lon = place.lon;
        if (source == _LocationSource.FROM) {
          context.read<LatLongProvider>().setFromLoc(lat, lon);
          setState(() {
            _fromTextController.text = place.name;
            _showDropdownFor_fromLocation = false; // close dropdown on select
          });
        } else if (source == _LocationSource.TO) {
          context.read<LatLongProvider>().setToLoc(lat, lon);
          setState(() {
            _showDropdownFor_toLocation = false; // close dropdown on select
            _toTextController.text = place.name;
          });
        }
      },
      child: Container(
        height: 60,
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Text(place.name),
            Text(place.displayName, style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
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
