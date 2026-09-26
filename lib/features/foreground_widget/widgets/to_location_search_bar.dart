import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/api/nominatim.dart';
import 'package:sakenph/features/foreground_widget/functions.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/transient_ui.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_search_details.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

class ToLocationSearchBar extends StatefulWidget {
  const ToLocationSearchBar();

  @override
  State<ToLocationSearchBar> createState() => _ToLocationSearchBarState();
}

class _ToLocationSearchBarState extends State<ToLocationSearchBar> {
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
      (value) => value.getSelectedToLocationDetails,
    );

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
                setState(() {
                  isFocused = hasFocus;
                });
                if (!hasFocus) {
                  tryToGetFirstResultAndSave(
                    searchDetailsProvider,
                    SearchFieldType.to,
                    mapHelperProvider,
                    systemVariablesProvider,
                    context,
                  );
                }
              },
              child: TextField(
                focusNode: searchDetailsProvider.getToLocFocusNode,
                controller: searchDetailsProvider.getToLocTextController,
                onChanged: (value) {
                  toLocTextFieldOnChanged(
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
                      SystemState.gatheringToLoc;
                  searchDetailsProvider.getToLocFocusNode.requestFocus();
                },
                decoration: InputDecoration(
                  isDense: true,

                  /// Expected to change state whether the background widget is
                  /// visible or not
                  hintText: searchDetailsProvider.toLocTextfieldHintText,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: responsiveSizeHeight(15),
                    horizontal: responsiveSizeWidth(15),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: SizedBox(
                    width: responsiveSizeHeight(24 + 15 + 7.5),
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: responsiveSizeWidth(24),
                    minHeight: responsiveSizeHeight(24),
                  ),

                  fillColor: manageTextfieldColor(
                    isFocused,
                    !mapHelperProvider.getIsToLocationDetailsEmpty,
                    searchDetailsProvider.getToLocTextController.text.isEmpty,
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
