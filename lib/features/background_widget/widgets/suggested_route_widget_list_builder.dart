// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/features/background_widget/functions.dart';
import 'package:sakenph/features/background_widget/widgets/suggested_route_widget_template.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';
import 'package:sakenph/providers/provider_map_helper.dart';

/// Builder of the widget list that contains suggested paths.
///
/// This widget is just a SizedBox that handles ListView.separated() operations
/// to form the interactable route widgets.
class SuggestedRouteWidgetListBuilder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> shortestPaths = context
        .read<MapHelperProvider>()
        .getSuggestedShortestPaths;
    final routeIds = rankSuggestedRouteIds(shortestPaths);

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.only(bottom: responsiveSizeHeight(100)),
            itemBuilder: (context, index) {
              return SuggestedRouteWidgetTemplate(
                choice_idx: index,
                route_id: routeIds[index],
              );
            },
            separatorBuilder: (context, index) =>
                SizedBox(height: responsiveSizeHeight(16)),
            itemCount: routeIds.length,
          ),
        ),
        SizedBox(height: responsiveSizeHeight(16)),
      ],
    );
  }
}
