import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart'
    show LoadingAnimationWidget;
import 'package:provider/provider.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

/// This widget is used to hide the map and to show its contents. Contents depend
/// on [SystemVariablesProvider.backWidgetCurrentState] current value.
class BackgroundWidget extends StatelessWidget {
  const BackgroundWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !context.select<SystemVariablesProvider, bool>(
        (varval) => (varval.backgroundWidgetVisibility),
      ),
      child: AnimatedOpacity(
        opacity:
            context.read<SystemVariablesProvider>().backgroundWidgetVisibility
            ? 1.0
            : 0.0,
        duration: Duration(milliseconds: 200),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,

          /// The intention for this is that if the user presses anywhere in the
          /// background widget, it would hide it. Think of it as a way to help
          /// users easily close down the background widget
          onTap: () {
            context
                .read<SystemVariablesProvider>()
                .setBackgroundWidgetVisibility(false);
          },
          child: PopScope(
            canPop: !context
                .read<SystemVariablesProvider>()
                .backgroundWidgetVisibility,
            onPopInvokedWithResult: (didPop, result) {
              print("[TEMP] Popping Attempt Occurred");
              if (!didPop) {
                context
                    .read<SystemVariablesProvider>()
                    .setBackgroundWidgetVisibility(false);
              }
            },
            child: Container(
              color: Colors.white,
              child: ViewForRequestingUserLoc(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget to use when you're requesting for the user's origin destination. Contains
/// a button that will get the user's current location and suggestions from their
/// inputs.
class ViewForRequestingUserLoc extends StatelessWidget {
  const ViewForRequestingUserLoc({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: 60),
        Align(
          child: GestureDetector(
            onTap: () {
              print("[TEMP] Will save user current loc");
            },
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1.0),
              ),
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(Icons.location_on),
                  Text(" Click to use your location"),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 60),
        Align(
          child: LoadingAnimationWidget.discreteCircle(
            color: Colors.black,
            size: 100,
          ),
        ),
      ],
    );
  }
}
