import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/classes/nominatim_response.dart';
import 'package:sakenph/features/background_widget/functions.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_search_details.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

/// Takes in information of a [NominatimPlace] object and creates a widget for
/// ListView out of it.
///
/// Can be reused if needed
class SearchResultRenderer extends StatefulWidget {
  final NominatimPlace nomiPlace;
  final SearchFieldType searchFieldType;

  const SearchResultRenderer({
    required this.nomiPlace,
    required this.searchFieldType,
  });

  @override
  State<SearchResultRenderer> createState() => _SearchResultRendererState();
}

class _SearchResultRendererState extends State<SearchResultRenderer> {
  /// Used alongside AnimatedContainer to show a tapping color effect
  bool _showColor = false;

  @override
  Widget build(BuildContext context) {
    // force rebuild upon res change
    MediaQuery.sizeOf(context);

    bool isPlaceOutOfScope = !isPlaceWithinScope(widget.nomiPlace.displayName);

    return AnimatedContainer(
      color: _showColor ? Colors.grey.shade400 : Colors.transparent,
      duration: Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: () async {
          if (widget.nomiPlace.name != "No Places Found") {
            MapHelperProvider mapHelperProvider = context
                .read<MapHelperProvider>();
            SystemVariablesProvider systemVariablesProvider = context
                .read<SystemVariablesProvider>();
            SearchDetailsProvider searchDetailsProvider = context
                .read<SearchDetailsProvider>();
            switch (widget.searchFieldType) {
              case SearchFieldType.from:
                mapHelperProvider.setFromLocationDetails = widget.nomiPlace;
                systemVariablesProvider.setAppCurrentState =
                    SystemState.gatheringToLoc;
                searchDetailsProvider.setFromLocTextfieldText =
                    widget.nomiPlace.name;
                searchDetailsProvider.requestFocusTowardsLocTextfield();
                break;
              case SearchFieldType.to:
                mapHelperProvider.setToLocationDetails = widget.nomiPlace;
                startComputingForRoutes(context);
                searchDetailsProvider.setToLocTextfieldText =
                    widget.nomiPlace.name;
                searchDetailsProvider.unfocusFromLocTextfield();
                break;
            }
          }
          setState(() {
            _showColor = true;
          });
          await Future.delayed(Duration(milliseconds: 50));
          setState(() {
            _showColor = false;
          });
        },
        child: Column(
          children: [
            Container(
              color: isPlaceOutOfScope
                  ? Color.fromARGB(100, 237, 111, 132)
                  : Colors.transparent,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: responsiveSizeHeight(8),
                  horizontal: 0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: responsiveSizeHeight(34),
                      height: responsiveSizeHeight(34),
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.location_on,
                        size: responsiveSizeHeight(24),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.nomiPlace.name,
                            style: TextStyle(
                              fontSize: responsiveSizeHeight(20),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.nomiPlace.displayName,
                            style: TextStyle(fontSize: responsiveSizeHeight(12)),
                            textAlign: TextAlign.left,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isPlaceOutOfScope)
                            Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.red, size: responsiveSizeHeight(16)),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      "This place is outside of this app's scope.",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: responsiveSizeHeight(13),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(color: Colors.black, height: responsiveSizeHeight(2)),
          ],
        ),
      ),
    );
  }
}
