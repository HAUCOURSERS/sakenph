import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:sakenph/api/nominatim.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/providers/provider_search_details.dart';
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

/// Relies on the value of [SystemVariablesProvider.appCurrentState] to
/// decide what to render.
class _ForegroundWidgetContentRenderer extends StatelessWidget {
  const _ForegroundWidgetContentRenderer();

  @override
  Widget build(BuildContext context) {
    bool isFromLocDetailsEmpty = context.select<SearchDetailsProvider, bool>(
      (value) => !value.isFromLocationDetailsEmpty,
    );
    SystemState systemState = context
        .select<SystemVariablesProvider, SystemState>(
          (value) => value.appCurrentState,
        );
    if (systemState != SystemState.peekAtRoute) {
      return (isFromLocDetailsEmpty)
          ? _FromLocationSearchBar()
          : Column(
              children: [_FromLocationSearchBar(), _ToLocationSearchBar()],
            );
    } else {
      return SizedBox.shrink();
    }
  }
}

/// A textfield widget that is used by the user to input their origin location
class _FromLocationSearchBar extends StatelessWidget {
  const _FromLocationSearchBar();

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
                context.read<SearchDetailsProvider>().tryToEraseLocResults(
                  SearchFieldType.from,
                );
                context.read<SearchDetailsProvider>().setTextfieldEmptyStatus(
                  value.isEmpty,
                  SearchFieldType.from,
                );
                if (value.isNotEmpty) {
                  EasyDebounce.debounce(
                    DebounceId.nominatim_fromLocationSearch.toString(),
                    Duration(seconds: 1),
                    () async {
                      context
                          .read<SearchDetailsProvider>()
                          .saveLocSearchResults(
                            await searchPlaces(value),
                            SearchFieldType.from,
                          );
                    },
                  );
                } else {
                  /// Covers the use case of: If the user clears out the entire textfield section
                  EasyDebounce.cancel(
                    DebounceId.nominatim_fromLocationSearch.toString(),
                  );
                }
              },
              style: TextStyle(fontSize: 18),
              onTap: () {
                context
                    .read<SystemVariablesProvider>()
                    .setBackgroundWidgetVisibility(true);
                context.read<SystemVariablesProvider>().setAppCurrentState(
                  SystemState.gatheringFromLoc,
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
  const _ToLocationSearchBar();

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
                context.read<SearchDetailsProvider>().tryToEraseLocResults(
                  SearchFieldType.to,
                );
                context.read<SearchDetailsProvider>().setTextfieldEmptyStatus(
                  value.isEmpty,
                  SearchFieldType.to,
                );
                if (value.isNotEmpty) {
                  EasyDebounce.debounce(
                    DebounceId.nominatim_toLocationSearch.toString(),
                    Duration(seconds: 1),
                    () async {
                      context
                          .read<SearchDetailsProvider>()
                          .saveLocSearchResults(
                            await searchPlaces(value),
                            SearchFieldType.to,
                          );
                    },
                  );
                } else {
                  /// Covers the use case of: If the user clears out the entire textfield section
                  EasyDebounce.cancel(
                    DebounceId.nominatim_fromLocationSearch.toString(),
                  );
                }
              },
              style: TextStyle(fontSize: 18),
              onTap: () {
                context
                    .read<SystemVariablesProvider>()
                    .setBackgroundWidgetVisibility(true);
                context.read<SystemVariablesProvider>().setAppCurrentState(
                  SystemState.gatheringToLoc,
                );
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
