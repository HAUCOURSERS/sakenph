import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/features/foreground_widget/functions.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/transient_ui.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';
import 'package:sakenph/pages/settings_page.dart' show SettingsPage;
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_search_details.dart';
import 'package:sakenph/providers/provider_system_data.dart';
import 'package:sakenph/providers/provider_system_vars.dart';
import 'package:sakenph/providers/provider_tutorial_mechanics.dart';

/// A textfield widget that is used by the user to input their origin location
class FromLocationSearchBar extends StatefulWidget {
  FromLocationSearchBar();

  @override
  State<FromLocationSearchBar> createState() => _FromLocationSearchBarState();
}

class _FromLocationSearchBarState extends State<FromLocationSearchBar> {
  // Used to manage the color of the widget to let the user know if there are issues with the
  // location input or not.
  //
  // If it's focused, the textfield's color will be white. otherwise it will be green/red
  bool isFocused = false;

  @override
  Widget build(BuildContext context) {
    SearchDetailsProvider searchDetailsProvider = context
        .read<SearchDetailsProvider>();
    MapHelperProvider mapHelperProvider = context.read<MapHelperProvider>();
    SystemVariablesProvider systemVariablesProvider = context
        .read<SystemVariablesProvider>();

    // Forcing re-renders when there's changes to the fromloc data. This is needed because
    // when the textfield is modified, any existing fromloc data is erased.
    context.select<MapHelperProvider, LatLng?>(
      (value) => value.getSelectedFromLocationDetails,
    );
    SystemDataProvider systemDataProvider = context.read<SystemDataProvider>();
    TutorialMechanicsProvider tutorialMechanicsProvider = context
        .read<TutorialMechanicsProvider>();

    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: responsiveSizeWidth(
          MediaQuery.sizeOf(context).width * 0.95,
          500,
        ),
        child: Column(
          children: [
            Focus(
              onFocusChange: (hasFocus) {
                /// For entering step 2 in tutorial
                if (hasFocus && systemDataProvider.isTutorialOngoing) {
                  tutorialMechanicsProvider.moveToStage02();
                }
                setState(() {
                  isFocused = hasFocus;
                });
                if (!hasFocus) {
                  tryToGetFirstResultAndSave(
                    searchDetailsProvider,
                    SearchFieldType.from,
                    mapHelperProvider,
                    systemVariablesProvider,
                    context,
                  );
                }
              },
              child: TextField(
                controller: searchDetailsProvider.getFromLocTextController,
                focusNode: searchDetailsProvider.getFromLocFocusNode,
                onChanged: (value) {
                  fromLocTextFieldOnChanged(
                    searchDetailsProvider,
                    value,
                    mapHelperProvider,
                  );
                },
                style: TextStyle(fontSize: responsiveSizeHeight(18)),
                onTap: () {
                  dismissTransientUi(context);
                  context
                          .read<SystemVariablesProvider>()
                          .setBackgroundWidgetVisibility =
                      true;
                  context.read<SystemVariablesProvider>().setAppCurrentState =
                      SystemState.gatheringFromLoc;
                  searchDetailsProvider.getFromLocFocusNode.requestFocus();
                },
                decoration: InputDecoration(
                  isDense: true,

                  /// Expected to change state whether the background widget is
                  /// visible or not
                  prefixIcon:
                      context.select<SystemVariablesProvider, bool>(
                        (varval) => (varval.backgroundWidgetVisibility),
                      )
                      ? Padding(
                          padding: EdgeInsets.only(
                            bottom: responsiveSizeHeight(5),
                            top: responsiveSizeHeight(5),
                            left: responsiveSizeHeight(15),
                            right: responsiveSizeHeight(7.5),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              dismissTransientUi(context);
                              context
                                      .read<SystemVariablesProvider>()
                                      .setBackgroundWidgetVisibility =
                                  false;
                            },
                            child: Icon(
                              Icons.arrow_back,
                              size: responsiveSizeHeight(24),
                            ),
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.only(
                            bottom: responsiveSizeHeight(5),
                            top: responsiveSizeHeight(5),
                            left: responsiveSizeHeight(15),
                            right: responsiveSizeHeight(7.5),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              dismissTransientUi(context);
                              context
                                      .read<SystemVariablesProvider>()
                                      .setBackgroundWidgetVisibility =
                                  true;
                            },
                            child: Icon(
                              Icons.search,
                              size: responsiveSizeHeight(24),
                            ),
                          ),
                        ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: responsiveSizeWidth(24),
                    minHeight: responsiveSizeHeight(24),
                  ),

                  hintText: searchDetailsProvider.fromLocTextfieldHintText,
                  suffixIcon: Padding(
                    padding: EdgeInsets.only(
                      bottom: responsiveSizeHeight(5),
                      top: responsiveSizeHeight(5),
                      left: responsiveSizeHeight(7.5),
                      right: responsiveSizeHeight(15),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SettingsPage(),
                          ),
                        );
                      },
                      child: Icon(
                        Icons.settings,
                        size: responsiveSizeHeight(24),
                      ),
                    ),
                  ),
                  suffixIconConstraints: BoxConstraints(
                    minWidth: responsiveSizeWidth(32),
                    minHeight: responsiveSizeHeight(24),
                  ),

                  contentPadding: EdgeInsets.symmetric(
                    vertical: responsiveSizeHeight(15),
                    horizontal: responsiveSizeWidth(15),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      responsiveSizeWidth(12),
                    ),
                  ),

                  fillColor: manageTextfieldColor(
                    isFocused,
                    !mapHelperProvider.getIsFromLocationDetailsEmpty,
                    searchDetailsProvider.getFromLocTextController.text.isEmpty,
                  ),
                  filled: true,
                ),
              ),
            ),
            SizedBox(height: responsiveSizeHeight(10)),
          ],
        ),
      ),
    );
  }
}
