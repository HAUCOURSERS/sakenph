import 'package:flutter/material.dart';
import 'package:sakenph/features/foreground_widget/widgets/active_route_terminator.dart';
import 'package:sakenph/features/foreground_widget/widgets/from_location_search_bar.dart';
import 'package:sakenph/features/foreground_widget/widgets/preview_window_for_suggested_path.dart';
import 'package:sakenph/features/foreground_widget/widgets/route_opener_button.dart';
import 'package:sakenph/features/foreground_widget/widgets/selected_location_decision_helper.dart';
import 'package:sakenph/features/foreground_widget/widgets/to_location_search_bar.dart';
import 'package:sakenph/features/foreground_widget/widgets.dart'
    show JeepneyRouteFloatingControl;
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/providers/provider_system_vars.dart';
import 'package:provider/provider.dart';

import '../../providers/provider_map_helper.dart';

/// The main widget for the Foreground. Any widgets that are needed to be displayed
/// at the top of the main widget's stack is written here.
class ForegroundWidget extends StatefulWidget {
  const ForegroundWidget({super.key});

  @override
  State<ForegroundWidget> createState() => _ForegroundWidgetState();
}

class _ForegroundWidgetState extends State<ForegroundWidget> {
  @override
  Widget build(BuildContext context) {
    final systemState = context.select<SystemVariablesProvider, SystemState>(
      (provider) => provider.appCurrentState,
    );
    final backgroundWidgetVisibility = context
        .select<SystemVariablesProvider, bool>(
          (provider) => provider.backgroundWidgetVisibility,
        );
    final showJeepneyControl =
        !backgroundWidgetVisibility &&
        (systemState == SystemState.gatheringFromLoc ||
            systemState == SystemState.gatheringToLoc ||
            systemState == SystemState.showSuggestedRoutes);

    return SafeArea(
      child: Stack(
        children: [
          _ForegroundWidgetContentRenderer(),
          if (showJeepneyControl) JeepneyRouteFloatingControl(),
        ],
      ),
    );
  }
}

/// Relies on the value of [SystemVariablesProvider.appCurrentState] to
/// decide what to render.
class _ForegroundWidgetContentRenderer extends StatelessWidget {
  const _ForegroundWidgetContentRenderer();

  @override
  Widget build(BuildContext context) {
    bool isFromLocDetailsEmpty = context.select<MapHelperProvider, bool>(
      (value) => value.getIsFromLocationDetailsEmpty,
    );
    bool hasSearchedForRoutes = context.select<MapHelperProvider, bool>(
      (value) => !value.getIsSuggestedShortestPathsEmpty,
    );
    SystemState systemState = context
        .select<SystemVariablesProvider, SystemState>(
          (value) => value.appCurrentState,
        );
    bool backgroundWidgetVisibility = context
        .select<SystemVariablesProvider, bool>(
          (value) => value.backgroundWidgetVisibility,
        );
    switch (systemState) {
      case SystemState.gatheringFromLoc:
      case SystemState.gatheringToLoc:
      case SystemState.waitingForBackendResponse:
      case SystemState.showSuggestedRoutes:
      case SystemState.backendRequestFail:
        return (isFromLocDetailsEmpty)
            ? FromLocationSearchBar()
            : Column(
                children: [
                  FromLocationSearchBar(),
                  ToLocationSearchBar(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: (hasSearchedForRoutes && !backgroundWidgetVisibility)
                        ? RouteOpenerButton()
                        : SizedBox.shrink(),
                  ),
                ],
              );
      case SystemState.peekAtRoute:
        return PreviewWindowForSuggestedPath();
      case SystemState.hideWidgets:
        return SizedBox.shrink();
      case SystemState.isCurrentlyTravelling:
        return ActiveRouteTerminator();
      case SystemState.confirmingLocationSelection:
        return SelectedLocationDecisionHelper();
    }
  }
}
