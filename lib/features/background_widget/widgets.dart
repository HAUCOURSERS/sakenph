import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart'
    show LoadingAnimationWidget;
import 'package:provider/provider.dart';
import 'package:sakenph/classes/nominatim_response.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/providers/provider_search_details.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

/// This widget is used to hide the map and to show its contents. Contents depend
/// on [SystemVariablesProvider.backWidgetCurrentState] current value.
class BackgroundWidget extends StatelessWidget {
  const BackgroundWidget({super.key});

  @override
  Widget build(BuildContext context) {
    bool backgroundWidgetVisibility = context
        .select<SystemVariablesProvider, bool>(
          (val) => val.backgroundWidgetVisibility,
        );
    return IgnorePointer(
      ignoring: !backgroundWidgetVisibility,
      child: AnimatedOpacity(
        opacity: backgroundWidgetVisibility ? 1.0 : 0.0,
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
              if (!didPop) {
                context
                    .read<SystemVariablesProvider>()
                    .setBackgroundWidgetVisibility(false);
              }
            },
            child: Container(
              color: Colors.white,
              child: _BackgroundWidgetContentRenderer(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Relies on the value of [SystemVariablesProvider.backWidgetCurrentState] to
/// decide what to render.
class _BackgroundWidgetContentRenderer extends StatelessWidget {
  const _BackgroundWidgetContentRenderer({super.key});

  @override
  Widget build(BuildContext context) {
    switch (context.select<SystemVariablesProvider, SystemStateEnum>(
      (val) => val.backWidgetCurrentState,
    )) {
      case SystemStateEnum.gatheringFromLoc:
        return ViewForRequestingUserLoc();
      case SystemStateEnum.gatheringToLoc:
        // TODO: Handle this case.
        return Container();
    }

    return Container();
  }
}

/// Widget to use when you're requesting for the user's origin destination. Contains
/// a button that will get the user's current location and suggestions from their
/// inputs.
class ViewForRequestingUserLoc extends StatelessWidget {
  const ViewForRequestingUserLoc({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isFromLocResultsEmpty = context
        .select<SearchDetailsProvider, bool>(
          (value) => value.fromLocResults.isEmpty,
        );
    final bool isTextfieldEmpty = context.select<SearchDetailsProvider, bool>(
      (value) => value.isFromLocTextfieldEmpty,
    );

    /// For building the choices in places
    Widget toShowSuggestionResults = isFromLocResultsEmpty
        ? Column(
            children: [
              SizedBox(height: 70),
              Align(
                child: LoadingAnimationWidget.discreteCircle(
                  color: Colors.black,
                  size: 100,
                ),
              ),
            ],
          )
        : Expanded(
            child: ListView.builder(
              itemBuilder: (context, index) => _SearchResultRenderer(
                nomiPlace: context
                    .read<SearchDetailsProvider>()
                    .fromLocResults[index],
              ),
              itemCount: context
                  .read<SearchDetailsProvider>()
                  .fromLocResults
                  .length,
            ),
          );

    return Column(
      children: [
        SizedBox(height: 60),
        if (context
            .read<SearchDetailsProvider>()
            .fromLocController
            .text
            .isNotEmpty)
          SizedBox(height: 60),
        Align(
          child: GestureDetector(
            onTap: () {
              /*
              context.read<SearchResultsProvider>().fromLocController.text =
                  "Your Current Location";
              context.read<SystemVariablesProvider>().setBackWidgetCurrentState(
                SystemStateEnum.gatheringToLoc,
              );
              context
                  .read<SearchResultsProvider>()
                  .toLocFocusNode
                  .requestFocus();
                  */
                  context.read<SearchDetailsProvider>().setFromLocResults(resultList)
            },
            child: Container(
              width: MediaQuery.sizeOf(context).width * 0.9,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1.0),
              ),
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(Icons.location_on),
                  Text(
                    " Click to use your location",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 10),
        if (!isTextfieldEmpty) toShowSuggestionResults,
      ],
    );
  }
}

/// Takes in information of a [NominatimPlace] object and creates a widget for
/// ListView out of it.
///
/// Can be reused if needed
class _SearchResultRenderer extends StatefulWidget {
  final NominatimPlace nomiPlace;
  const _SearchResultRenderer({super.key, required this.nomiPlace});

  @override
  State<_SearchResultRenderer> createState() => _SearchResultRendererState();
}

class _SearchResultRendererState extends State<_SearchResultRenderer> {
  bool _showColor = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      color: _showColor ? Colors.grey.shade400 : Colors.transparent,
      duration: Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: () async {
          if (widget.nomiPlace.name != "No Places Found") {
            context.read<SearchDetailsProvider>().fromLocController.text =
                widget.nomiPlace.name;
            context.read<SystemVariablesProvider>().setBackWidgetCurrentState(
              SystemStateEnum.gatheringToLoc,
            );
          }
          setState(() {
            _showColor = true;
          });
          await Future.delayed(Duration(milliseconds: 50));
          setState(() {
            _showColor = false;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
          ),
          child: ListTile(
            title: Row(
              children: [
                Icon(Icons.location_on),
                SizedBox(width: 10, height: 0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nomiPlace.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.nomiPlace.displayName,
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
