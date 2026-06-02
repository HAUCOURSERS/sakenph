import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:sakenph/classes/nominatim_response.dart';
import 'package:sakenph/features/home_page/functions.dart'
    show fetchData, handleLocationPermission, searchPlaces;
import 'package:sakenph/features/home_page/other_widgets.dart';
import 'package:sakenph/map_widget.dart';
import 'package:sakenph/providers/provider_selected_loc.dart';
import 'package:sakenph/providers/provider_system_vars.dart'
    show SystemVariablesProvider;
import 'package:sakenph/settings_page.dart';
import 'package:provider/provider.dart';
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

  final TextEditingController _fromTextController = TextEditingController();
  final TextEditingController _toTextController = TextEditingController();

  /// Whether to display the dropdown visual
  // ignore: non_constant_identifier_names
  bool _showDropdownFor_fromLocation = false;
  // ignore: non_constant_identifier_names
  bool _showDropdownFor_toLocation = false;
  bool _isLoading = true;
  List<NominatimPlace> _toLocationResults = [];

  /// Calls Nominatim Public API to do searches. This function has to be inside of this
  /// state class to perform setState() calls.
  void querySearchPlaces(String query) async {
    print("[TEMP] searchPlaces() called!");

    setState(() {
      _isLoading = true;
      _toLocationResults = [];
    });

    final results = await searchPlaces(query);

    setState(() {
      _isLoading = false;
      _toLocationResults = results;
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
          SafeArea(child: Stack(children: [FromLocationSearchBar()])),
        ],
      ),
    );
  }
}
