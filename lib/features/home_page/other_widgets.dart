import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'
    show Position, Geolocator, LocationAccuracy;
import 'package:sakenph/providers/provider_selected_loc.dart';
import 'package:sakenph/providers/provider_system_vars.dart';
import 'package:sakenph/settings_page.dart' show SettingsPage;
import 'package:provider/provider.dart';

/// A textfield widget that is used by the user to input their origin location
class FromLocationSearchBar extends StatelessWidget {
  const FromLocationSearchBar({super.key});

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
                onTap: () {
                  context
                      .read<SystemVariablesProvider>()
                      .setBackgroundWidgetVisibility(true);
                },
                decoration: InputDecoration(
                  /// Expected to change state whether the background widget is
                  /// visible or not
                  prefixIcon:
                      context.select<SystemVariablesProvider, bool>(
                        (varval) => (varval.backgroundWidgetVisibility),
                      )
                      ? GestureDetector(
                          onTap: () {
                            context
                                .read<SystemVariablesProvider>()
                                .setBackgroundWidgetVisibility(false);
                          },
                          child: Icon(Icons.arrow_back),
                        )
                      : Icon(Icons.search),
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
class BackgroundWidget extends StatelessWidget {
  const BackgroundWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !context.select<SystemVariablesProvider, bool>(
        (varval) => (varval.backgroundWidgetVisibility),
      ),
      child: AnimatedOpacity(
        opacity:
            context.read<SystemVariablesProvider>().backgroundWidgetVisibility
            ? 1.0
            : 0.0,
        duration: Duration(milliseconds: 200),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,

          /// The intention for this is that if the user presses anywhere in the
          /// background widget, it would hide it. Think of it as a way to help
          /// users easily close down the background widget
          onTap: () {
            context
                .read<SystemVariablesProvider>()
                .setBackgroundWidgetVisibility(false);
          },
          child: PopScope(
            canPop: !context
                .read<SystemVariablesProvider>()
                .backgroundWidgetVisibility,
            onPopInvokedWithResult: (didPop, result) {
              print("[TEMP] Popping Attempt Occurred");
              if (!didPop) {
                context
                    .read<SystemVariablesProvider>()
                    .setBackgroundWidgetVisibility(false);
              }
            },
            child: Container(
              color: Colors.white,
              child: ViewForRequestingUserLoc(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget to use when you're requesting for the user's origin destination
///

class ViewForRequestingUserLoc extends StatelessWidget {
  const ViewForRequestingUserLoc({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: 60),
        Align(
          child: GestureDetector(
            onTap: () {
              print("[TEMP] Will save user current loc");
            },
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
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
    );
  }
}
