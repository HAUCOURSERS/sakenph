import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'
    show Position, Geolocator, LocationAccuracy;
import 'package:sakenph/settings_page.dart' show SettingsPage;

class FromLocationSearchBar extends StatelessWidget {
  final bool showUserResultsHolder;
  final VoidCallback onSearchTap;
  final VoidCallback onBackTap;

  const FromLocationSearchBar({
    super.key,
    required this.showUserResultsHolder,
    required this.onSearchTap,
    required this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.95,
          child: Column(
            children: [
              TextField(
                style: TextStyle(fontSize: 18),
                onTap: onSearchTap, // ✅ callback from parent
                decoration: InputDecoration(
                  prefixIcon: showUserResultsHolder == false
                      ? Icon(Icons.search)
                      : GestureDetector(
                          onTap: onBackTap, // ✅ callback from parent
                          child: Icon(Icons.arrow_back),
                        ),
                  hintText: "Your Location",
                  suffixIcon: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      );
                    },
                    child: Icon(Icons.settings),
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
    );
  }
}

/// This widget is used to hide the map and to show its contents. Contents depend
/// on the current state of setting the "From" and "To" locations
class BackWidget extends StatelessWidget {
  final bool showUserResultsHolder;
  final VoidCallback hideResultsHolder;

  const BackWidget({
    super.key,
    required this.showUserResultsHolder,
    required this.hideResultsHolder,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !showUserResultsHolder,
      child: AnimatedOpacity(
        opacity: showUserResultsHolder ? 1.0 : 0.0,
        duration: Duration(milliseconds: 200),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: hideResultsHolder,
          child: PopScope(
            canPop: !showUserResultsHolder,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) {
                hideResultsHolder;
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
                        Position position = await Geolocator.getCurrentPosition(
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
                          border: Border.all(color: Colors.black, width: 1.0),
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
    );
  }
}
