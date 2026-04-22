import 'package:flutter/material.dart';
import 'package:sakenph/classes/nominatim_response.dart';
import 'package:sakenph/functions/functions_home_page.dart'
    show searchPlaces, fetchData;
import 'package:sakenph/map_widget.dart';
import 'package:sakenph/providers/provider_selected_loc.dart';
import 'package:sakenph/settings_page.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  late Future<Map<dynamic, dynamic>> json;
  String originName = '';
  String destName = '';

  /// Whether to display the dropdown visual
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        title: ListTile(
          title: Text("SakenPH"),
          trailing: PopupMenuButton(
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'Settings', child: Text('Settings')),
            ],
            onSelected: (value) async {
              if (value == 'Settings') {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => SettingsPage()));
              }
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () async {}),
      body: Stack(
        children: [
          MapWidget(),
          Center(
            child: Column(
              children: [
                /// From Location
                Container(
                  width: 320,
                  height: 40,
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    color: const Color.fromARGB(255, 227, 241, 255),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Padding(
                    padding: EdgeInsetsGeometry.all(5),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Enter From Location: Hardcoded for now",
                      ),
                    ),
                  ),
                ),

                /// To Location
                Container(
                  width: 320,
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    color: const Color.fromARGB(255, 227, 241, 255),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsetsGeometry.all(5),
                        child: TextField(
                          onSubmitted: (value) {
                            setState(() {
                              _showDropdownFor_toLocation = true;
                            });
                            querySearchPlaces(value);
                          },
                          decoration: InputDecoration(
                            hintText: "Enter To Location:",
                          ),
                        ),
                      ),

                      if (_showDropdownFor_toLocation)
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 200),
                          child: _isLoading
                              // show loading indicator while waiting
                              ? Center(child: CircularProgressIndicator())
                              // show results once returned
                              : ListView.separated(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.all(5),
                                  itemCount: _toLocationResults.length,
                                  separatorBuilder: (context, index) =>
                                      Divider(color: Colors.grey, height: 1),
                                  itemBuilder: (context, index) {
                                    final place = _toLocationResults[index];
                                    return GestureDetector(
                                      onTap: () {
                                        final lat = place.lat;
                                        final lon = place.lon;
                                        context
                                            .read<LatLongProvider>()
                                            .setToLoc(lat, lon);
                                        setState(() {
                                          _showDropdownFor_toLocation =
                                              false; // close dropdown on select
                                        });
                                      },
                                      child: Container(
                                        height: 40,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text(place.name),
                                      ),
                                    );
                                  },
                                ),
                        ),
                    ],
                  ),
                ),

                Container(
                  width: 320,
                  height: 40,
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    color: const Color.fromARGB(255, 227, 241, 255),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Center(
                    child: FutureBuilder(
                      future: json,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(snapshot.data!['key']);
                        } else {
                          return Text('${snapshot.error}');
                        }
                      },
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
