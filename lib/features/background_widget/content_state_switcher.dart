// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/features/background_widget/widgets/display_suggested_paths.dart';
import 'package:sakenph/features/background_widget/widgets/view_for_requesting_from_location.dart';
import 'package:sakenph/features/background_widget/widgets/view_for_requesting_to_location.dart';
import 'package:sakenph/features/background_widget/widgets/waiting_for_backend_response.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

/// This widget is used to hide the map and to show its contents. Contents depend
/// on [SystemVariablesProvider.appCurrentState] current value.
class BackgroundWidget extends StatelessWidget {
  const BackgroundWidget({super.key});

  @override
  Widget build(BuildContext context) {
    bool backgroundWidgetVisibility = context
        .select<SystemVariablesProvider, bool>(
          (val) => val.backgroundWidgetVisibility,
        );
    SystemState currentSystemState = context
        .select<SystemVariablesProvider, SystemState>(
          (val) => val.appCurrentState,
        );
    Color backgroundWidgetColor = context
        .select<SystemVariablesProvider, Color>(
          (value) => value.backgroundWidgetColor,
        );

    return IgnorePointer(
      ignoring: !backgroundWidgetVisibility,
      child: AnimatedOpacity(
        opacity: backgroundWidgetVisibility ? 1.0 : 0.0,
        duration: Duration(milliseconds: 300),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,

          /// The intention for this is that if the user presses anywhere in the
          /// background widget, it would hide it. Think of it as a way to help
          /// users easily close down the background widget
          ///
          /// However the app may go into a state where its peeking at the selected route.
          /// During this time, the auto hide will be disabled.
          onTap: () {
            if (currentSystemState != SystemState.peekAtRoute) {
              context
                      .read<SystemVariablesProvider>()
                      .setBackgroundWidgetVisibility =
                  false;
            }
          },
          child: PopScope(
            canPop: !context
                .read<SystemVariablesProvider>()
                .backgroundWidgetVisibility,
            onPopInvokedWithResult: (didPop, result) {
              //print("Pop Trigger $didPop");
              if (!didPop && currentSystemState != SystemState.peekAtRoute) {
                context
                        .read<SystemVariablesProvider>()
                        .setBackgroundWidgetVisibility =
                    false;
              }
            },
            child: Container(
              color: backgroundWidgetColor,
              child: _BackgroundWidgetContentRenderer(
                currentSystemState: currentSystemState,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Relies on the value of [SystemVariablesProvider.appCurrentState] to
/// decide what to render.
class _BackgroundWidgetContentRenderer extends StatelessWidget {
  final SystemState currentSystemState;

  const _BackgroundWidgetContentRenderer({required this.currentSystemState});

  @override
  Widget build(BuildContext context) {
    Widget child;
    switch (currentSystemState) {
      case SystemState.gatheringFromLoc:
        child = ViewForRequestingFromLocation();
        break;
      case SystemState.gatheringToLoc:
        child = ViewForRequestingToLocation();
        break;
      case SystemState.waitingForBackendResponse:
        child = WaitingForBackendResponse();
        break;
      case SystemState.showSuggestedRoutes:
        child = DisplaySuggestedPaths();
        break;
      case SystemState.peekAtRoute:
      case SystemState.hideWidgets:
      case SystemState.isCurrentlyTravelling:
      case SystemState.confirmingLocationSelection:
        child = SizedBox.shrink();
        break;
      case SystemState.backendRequestFail:
        throw UnimplementedError(
          "The backend request failed. This state is not yet implemented.",
        );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(key: ValueKey(currentSystemState), child: child),
    );
  }
}
