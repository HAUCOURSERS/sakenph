import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:sakenph/classes/nominatim_response.dart';
import 'package:sakenph/features/home_page/functions.dart'
    show fetchData, handleLocationPermission, searchPlaces;
import 'package:sakenph/map_widget.dart';
import 'package:sakenph/providers/provider_selected_loc.dart';
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
  String originName = '';
  String destName = '';

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

  bool _showUserResultsHolder = false;

  @override
  Widget build(BuildContext context) {
    handleLocationPermission(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          MapWidget(),
          IgnorePointer(
            ignoring: !_showUserResultsHolder,
            child: AnimatedOpacity(
              opacity: _showUserResultsHolder ? 1.0 : 0.0,
              duration: Duration(milliseconds: 200),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  setState(() {
                    _showUserResultsHolder = false;
                  });
                },
                child: PopScope(
                  canPop: !_showUserResultsHolder,
                  onPopInvokedWithResult: (didPop, result) {
                    if (!didPop) {
                      setState(() {
                        print("[TEMP] PopScope triggered!");
                        _showUserResultsHolder = false;
                      });
                    }
                  },
                  child: Container(
                    color: Colors.white,
                    child: ListView(
                      children: [
                        SizedBox(height: 60),
                        Align(
                          child: GestureDetector(
                            onTap: () async {
                              Position position =
                                  await Geolocator.getCurrentPosition(
                                    desiredAccuracy: LocationAccuracy.low,
                                  );
                              print(
                                "[TEMP] Obtained Location: " +
                                    position.latitude.toString() +
                                    " | " +
                                    position.longitude.toString(),
                              );
                              setState(() {
                                context.read<LatLongProvider>().setFromLoc(
                                  position.latitude,
                                  position.longitude,
                                );
                              });
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.95,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1.0,
                                ),
                              ),
                              padding: EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  Icon(Icons.location_on),
                                  Text(" Click to use your location"),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.95,
                      child: Column(
                        children: [
                          TextField(
                            style: TextStyle(fontSize: 18),
                            onTap: () {
                              setState(() {
                                print("[TEMP] TextStyle onTap() Triggered");
                                _showUserResultsHolder = true;
                              });
                            },
                            decoration: InputDecoration(
                              prefixIcon: Container(
                                child: _showUserResultsHolder == false
                                    ? Icon(Icons.search)
                                    : GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _showUserResultsHolder = false;
                                          });
                                        },
                                        child: Icon(Icons.arrow_back),
                                      ),
                              ),
                              hintText: "Your Location",
                              suffixIcon: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SettingsPage(),
                                    ),
                                  );
                                },
                                child: Container(child: Icon(Icons.settings)),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 5,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              fillColor: Colors.white,
                              filled: true,
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
