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
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFF1A73E8).withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 18,
                    color: Color(0xFF1A73E8),
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "Show other routes visited by A*",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF1A73E8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.only(bottom: responsiveSizeHeight(100)),
            itemBuilder: (context, index) {
              return SuggestedPathWidgetTemplate(choice_idx: index);
            },
            separatorBuilder: (context, index) =>
                SizedBox(height: responsiveSizeHeight(16)),
            itemCount: shortestPaths.length,
          ),
        ),
        SizedBox(height: responsiveSizeHeight(16)),
        footerWidget(),
      ],
    );
  }
}
