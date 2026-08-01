// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/features/background_widget/widgets/suggested_path_widget_template.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

/// Builder of the widget list that contains suggested paths.
///
/// This widget is just a SizedBox that handles ListView.separated() operations
/// to form the interactable route widgets.
class SuggestedPathWidgetListBuilder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> shortestPaths = context
        .read<MapHelperProvider>()
        .getSuggestedShortestPaths["routes"];

    Widget footerWidget() {
      return Column(
        children: [
          GestureDetector(
            onTap: () async {
              MapHelperProvider mapHelperProvider = context
                  .read<MapHelperProvider>();
              SystemVariablesProvider systemVariablesProvider = context
                  .read<SystemVariablesProvider>();

              Map<String, dynamic> suggestedShortestPaths =
                  mapHelperProvider.getSuggestedShortestPaths;
              Iterable<String> route_keys =
                  suggestedShortestPaths['checked_edges'].keys;
              systemVariablesProvider.setAppCurrentState =
                  SystemState.peekAtRoute;

              for (String route_key in route_keys) {
                await mapHelperProvider.mapWidgetController
                    .drawPathWithOneSourceRef(
                      mapHelperProvider.getFilteredRouteByID_Visiting(
                        route_key,
                      ),
                      mapHelperProvider,
                    );
                break; // only once
              }
            },
            child: SizedBox(
              width: responsiveSizeWidth(
                MediaQuery.sizeOf(context).width * 0.6,
              ),
              child: Container(
                padding: EdgeInsets.all(responsiveSizeHeight(10)),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(responsiveSizeHeight(5)),
                  border: Border.all(
                    color: Colors.black,
                    width: responsiveSizeHeight(1),
                  ),
                  // black outline
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: Offset(0, 3), // shadow goes downward
                    ),
                  ],
                ),
                child: Text(
                  "Press to show other routes visited by A*",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: responsiveSizeHeight(20),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics:
              NeverScrollableScrollPhysics(), // avoid nested-scroll conflicts
          itemBuilder: (context, index) {
            return SuggestedPathWidgetTemplate(choice_idx: index);
          },
          separatorBuilder: (context, index) =>
              SizedBox(height: responsiveSizeHeight(15)),
          itemCount: shortestPaths.length,
        ),
        SizedBox(height: responsiveSizeHeight(15)),
        footerWidget(),
      ],
    );
  }
}
