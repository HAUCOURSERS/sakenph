import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/api/nominatim.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';
import 'package:sakenph/providers/provider_search_details.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

class ToLocationSearchBar extends StatelessWidget {
  const ToLocationSearchBar();

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
              focusNode: searchDetailsProvider.getToLocFocusNode,
              controller: searchDetailsProvider.getToLocTextController,
              onChanged: (value) {
                searchDetailsProvider.tryToEraseLocResults(SearchFieldType.to);
                searchDetailsProvider.setIsNominatimSearchFailed_TypeTo = false;
                searchDetailsProvider.setActiveSearching_toLoc =
                    value.isNotEmpty;
                if (value.isNotEmpty) {
                  EasyDebounce.debounce(
                    DebounceId.nominatim_toLocationSearch.toString(),
                    Duration(seconds: 1),
                    () async {
                      context
                          .read<SearchDetailsProvider>()
                          .saveLocSearchResults(
                            await searchPlaces(
                              value,
                              searchDetailsProvider,
                              SearchFieldType.to,
                            ),
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
              style: TextStyle(fontSize: responsiveSizeHeight(18)),
              onTap: () {
                context
                        .read<SystemVariablesProvider>()
                        .setBackgroundWidgetVisibility =
                    true;
                context.read<SystemVariablesProvider>().setAppCurrentState =
                    SystemState.gatheringToLoc;
              },
              decoration: InputDecoration(
                isDense: true,

                /// Expected to change state whether the background widget is
                /// visible or not
                hintText: "Your Destination",
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
