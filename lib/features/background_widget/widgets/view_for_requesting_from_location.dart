import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/api/nominatim.dart';
import 'package:sakenph/features/background_widget/widgets/search_results_renderer.dart';
import 'package:sakenph/features/background_widget/widgets/use_current_location_button.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_search_details.dart';

/// Widget to use when you're requesting for the user's origin destination. Contains
/// a button that will get the user's current location and suggestions from their
/// inputs.
class ViewForRequestingFromLocation extends StatefulWidget {
  const ViewForRequestingFromLocation({super.key});

  @override
  State<ViewForRequestingFromLocation> createState() =>
      _ViewForRequestingFromLocationState();
}

class _ViewForRequestingFromLocationState
    extends State<ViewForRequestingFromLocation> {
  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context); // force reload upon resolution change

    final bool isFromLocResultsEmpty = context
        .select<SearchDetailsProvider, bool>(
          (value) => value.getFromLocSearchResults.isEmpty,
        );
    final bool isActiveSearching = context.select<SearchDetailsProvider, bool>(
      (value) => value.isActiveSearching_fromLoc,
    );
    final bool isNominatimSearchFailed = context
        .select<SearchDetailsProvider, bool>(
          (value) => value.isNominatimSearchFailed_TypeFrom,
        );

    final SearchDetailsProvider searchDetailsProvider = context
        .read<SearchDetailsProvider>();

    /// For building the choices in places
    Widget toShowSuggestionResults() {
      if (isFromLocResultsEmpty) {
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
                            print("flag 1");
                            searchDetailsProvider.tryToEraseLocResults(
                              SearchFieldType.from,
                            );
                            searchDetailsProvider
                                    .setIsNominatimSearchFailed_TypeFrom =
                                false;
                            await Future.delayed(Duration(milliseconds: 750));
                            searchDetailsProvider.saveLocSearchResults(
                              await searchPlaces(
                                searchDetailsProvider
                                    .getFromLocTextController
                                    .text,
                                searchDetailsProvider,
                                SearchFieldType.from,
                              ),
                              SearchFieldType.from,
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
              itemBuilder: (context, index) => SearchResultRenderer(
                searchFieldType: SearchFieldType.from,
                nomiPlace: context
                    .read<SearchDetailsProvider>()
                    .getFromLocSearchResults[index],
              ),
              itemCount: context
                  .read<SearchDetailsProvider>()
                  .getFromLocSearchResults
                  .length,
            ),
          );
        }
      }
    }

    return Column(
      children: [
        SizedBox(height: responsiveSizeHeight(60)),
        if (!context.read<MapHelperProvider>().getIsFromLocationDetailsEmpty)
          SizedBox(height: responsiveSizeHeight(60)),
        UseCurrentLocationButton(),
        SizedBox(height: responsiveSizeHeight(10)),
        if (isActiveSearching) toShowSuggestionResults(),
      ],
    );
  }
}
