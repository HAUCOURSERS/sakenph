// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart'
    show LoadingAnimationWidget;
import 'package:provider/provider.dart';
import 'package:sakenph/api/nominatim.dart';
import 'package:sakenph/features/background_widget/widgets/search_results_renderer.dart';
import 'package:sakenph/features/background_widget/widgets/use_current_location_button.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_search_details.dart';

class ViewForRequestingToLocation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // to rebuild upon res change
    MediaQuery.sizeOf(context);

    final bool isToLocResultsEmpty = context
        .select<SearchDetailsProvider, bool>(
          (value) => value.getToLocSearchResults.isEmpty,
        );
    final bool isActiveSearching = context.select<SearchDetailsProvider, bool>(
      (value) => value.isActiveSearching_toLoc,
    );
    final bool isNominatimSearchFailed = context
        .select<SearchDetailsProvider, bool>(
          (value) => value.isNominatimSearchFailed_TypeTo,
        );
    final SearchDetailsProvider searchDetailsProvider = context
        .read<SearchDetailsProvider>();

    /// For building the choices in places
    Widget toShowSuggestionResults() {
      if (isToLocResultsEmpty) {
        // Stalling page while waiting for api response
        return Column(
          children: [
            SizedBox(height: responsiveSizeHeight(70)),
            Align(
              child: LoadingAnimationWidget.discreteCircle(
                color: Colors.black,
                size: responsiveSizeHeight(100),
              ),
            ),
          ],
        );
      } else {
        // Nominatim api has returned something
        if (isNominatimSearchFailed) {
          return GestureDetector(
            onTap: () {},
            child: Container(
              color: Colors.grey.shade100,
              child: Column(
                children: [
                  SizedBox(height: responsiveSizeHeight(70)),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "Connection error for location search.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: responsiveSizeHeight(20),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: responsiveSizeHeight(30)),
                        GestureDetector(
                          onTap: () async {
                            searchDetailsProvider.tryToEraseLocResults(
                              SearchFieldType.to,
                            );
                            searchDetailsProvider
                                    .setIsNominatimSearchFailed_TypeTo =
                                false;
                            await Future.delayed(Duration(milliseconds: 1100));
                            searchDetailsProvider.saveLocSearchResults(
                              await searchPlaces(
                                searchDetailsProvider
                                    .getToLocTextController
                                    .text,
                                searchDetailsProvider,
                                SearchFieldType.to,
                              ),
                              SearchFieldType.to,
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.only(
                              bottom: responsiveSizeHeight(12),
                              top: responsiveSizeHeight(12),
                              left: responsiveSizeWidth(50),
                              right: responsiveSizeWidth(50),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade600,
                              boxShadow: [
                                BoxShadow(color: Colors.black, blurRadius: 2.0),
                              ],
                            ),
                            child: Text(
                              "RETRY",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: responsiveSizeHeight(15),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: responsiveSizeHeight(30)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(top: responsiveSizeHeight(10)),
              itemBuilder: (context, index) => SearchResultRenderer(
                searchFieldType: SearchFieldType.to,
                nomiPlace: searchDetailsProvider.getToLocSearchResults[index],
              ),
              itemCount: searchDetailsProvider.getToLocSearchResults.length,
            ),
          );
        }
      }
    }

    return Column(
      children: [
        SizedBox(height: responsiveSizeHeight(60)),
        Container(),
        SizedBox(height: responsiveSizeHeight(60)),
        if (isActiveSearching) toShowSuggestionResults(),
      ],
    );
  }
}
