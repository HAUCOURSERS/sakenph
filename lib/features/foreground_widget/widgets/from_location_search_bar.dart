import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/api/nominatim.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/transient_ui.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';
import 'package:sakenph/pages/settings_page.dart' show SettingsPage;
import 'package:sakenph/providers/provider_search_details.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

/// A textfield widget that is used by the user to input their origin location
class FromLocationSearchBar extends StatelessWidget {
  const FromLocationSearchBar();

  @override
  Widget build(BuildContext context) {
    SearchDetailsProvider searchDetailsProvider = context
        .read<SearchDetailsProvider>();

    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: responsiveSizeWidth(
          MediaQuery.sizeOf(context).width * 0.95,
          500,
        ),
        child: Column(
          children: [
            TextField(
              controller: searchDetailsProvider.getFromLocTextController,
              focusNode: searchDetailsProvider.getFromLocFocusNode,
              onChanged: (value) {
                searchDetailsProvider.tryToEraseLocResults(
                  SearchFieldType.from,
                );
                searchDetailsProvider.setIsNominatimSearchFailed_TypeFrom =
                    false;
                searchDetailsProvider.setActiveSearching_fromLoc =
                    value.isNotEmpty;
                if (value.isNotEmpty) {
                  EasyDebounce.debounce(
                    DebounceId.nominatim_fromLocationSearch.toString(),
                    Duration(seconds: 1),
                    () async {
                      searchDetailsProvider.saveLocSearchResults(
                        await searchPlaces(
                          value,
                          searchDetailsProvider,
                          SearchFieldType.from,
                        ),
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

                hintText: "Your Location",
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
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      );
                    },
                    child: Icon(Icons.settings, size: responsiveSizeHeight(24)),
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
                  borderRadius: BorderRadius.circular(responsiveSizeWidth(12)),
                ),

                fillColor: Colors.white,
                filled: true,
              ),
            ),
            SizedBox(height: responsiveSizeHeight(10)),
          ],
        ),
      ),
    );
  }
}
