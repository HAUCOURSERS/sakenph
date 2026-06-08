import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'
    show Position, Geolocator, LocationAccuracy;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sakenph/api/nominatim.dart';
import 'package:sakenph/features/background_widget/widgets.dart'
    show ViewForRequestingUserLoc;
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/providers/provider_search_details.dart';
import 'package:sakenph/providers/provider_selected_loc.dart';
import 'package:sakenph/providers/provider_system_vars.dart';
import 'package:sakenph/pages/settings_page.dart' show SettingsPage;
import 'package:provider/provider.dart';

/// The main widget for the Foreground. Any widgets that are needed to be displayed
/// at the top of the main widget's stack is written here.
class ForegroundWidget extends StatefulWidget {
  const ForegroundWidget({super.key});

  @override
  State<ForegroundWidget> createState() => _ForegroundWidgetState();
}

class _ForegroundWidgetState extends State<ForegroundWidget> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(children: [_ForegroundWidgetContentRenderer()]),
    );
  }
}

/// Relies on the value of [SystemVariablesProvider.backWidgetCurrentState] to
/// decide what to render.
class _ForegroundWidgetContentRenderer extends StatelessWidget {
  const _ForegroundWidgetContentRenderer({super.key});

  @override
  Widget build(BuildContext context) {
    switch (context.select<SystemVariablesProvider, SystemStateEnum>(
      (value) => value.backWidgetCurrentState,
    )) {
      case SystemStateEnum.gatheringFromLoc:
      case SystemStateEnum.gatheringToLoc:
        return context
                .read<SearchDetailsProvider>()
                .fromLocController
                .text
                .isEmpty
            ? _FromLocationSearchBar()
            : Column(
                children: [_FromLocationSearchBar(), _ToLocationSearchBar()],
              );
    }

    return Container();
  }
}

/// A textfield widget that is used by the user to input their origin location
class _FromLocationSearchBar extends StatelessWidget {
  const _FromLocationSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.95,
        child: Column(
          children: [
            TextField(
              controller: context
                  .read<SearchDetailsProvider>()
                  .fromLocController,
              onChanged: (value) {
                context
                    .read<SearchDetailsProvider>()
                    .tryToEraseFromLocResults();
                context
                    .read<SearchDetailsProvider>()
                    .setIsFromLocTextfieldEmpty(value.isEmpty);
                if (value.isNotEmpty) {
                  EasyDebounce.debounce(
                    DebounceIdEnum.nominatim_fromLocationSearch.toString(),
                    Duration(seconds: 1),
                    () async {
                      context.read<SearchDetailsProvider>().setFromLocResults(
                        await searchPlaces(value),
                      );
                    },
                  );
                } else {
                  /// Covers the use case of: If the user clears out the entire textfield section
                  EasyDebounce.cancel(
                    DebounceIdEnum.nominatim_fromLocationSearch.toString(),
                  );
                }
              },
              style: TextStyle(fontSize: 18),
              onTap: () {
                context
                    .read<SystemVariablesProvider>()
                    .setBackgroundWidgetVisibility(true);
                context
                    .read<SystemVariablesProvider>()
                    .setBackWidgetCurrentState(
                      SystemStateEnum.gatheringFromLoc,
                    );
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
    );
  }
}

class _ToLocationSearchBar extends StatelessWidget {
  const _ToLocationSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.95,
        child: Column(
          children: [
            TextField(
              focusNode: context.read<SearchDetailsProvider>().toLocFocusNode,
              controller: context.read<SearchDetailsProvider>().toLocController,
              onChanged: (value) {
                context
                    .read<SearchDetailsProvider>()
                    .tryToEraseFromLocResults();
                context
                    .read<SearchDetailsProvider>()
                    .setIsFromLocTextfieldEmpty(value.isEmpty);
                if (value.isNotEmpty) {
                  EasyDebounce.debounce(
                    DebounceIdEnum.nominatim_fromLocationSearch.toString(),
                    Duration(seconds: 1),
                    () async {
                      context.read<SearchDetailsProvider>().setFromLocResults(
                        await searchPlaces(value),
                      );
                    },
                  );
                } else {
                  /// Covers the use case of: If the user clears out the entire textfield section
                  EasyDebounce.cancel(
                    DebounceIdEnum.nominatim_fromLocationSearch.toString(),
                  );
                }
              },
              style: TextStyle(fontSize: 18),
              onTap: () {
                context
                    .read<SystemVariablesProvider>()
                    .setBackgroundWidgetVisibility(true);
              },
              decoration: InputDecoration(
                /// Expected to change state whether the background widget is
                /// visible or not
                hintText: "Your Destination",
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 48,
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
    );
  }
}
