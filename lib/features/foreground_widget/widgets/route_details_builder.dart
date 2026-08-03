import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/features/foreground_widget/functions.dart';
import 'package:sakenph/globals/functions/computations.dart';
import 'package:sakenph/globals/functions/formattings.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';
import 'package:sakenph/providers/provider_map_helper.dart';

/// Used by _PreviewWindowForSuggestedPath. Builds the Row() widgets to form
/// the display
class RouteDetailsBuilder extends StatelessWidget {
  const RouteDetailsBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    // force update during res change
    MediaQuery.sizeOf(context);
    // Cap the visible list height — beyond this it scrolls.
    double maxListHeight = responsiveSizeHeight(260.0);
    // Roughly how tall one row is, used to decide whether scrolling/fade is even needed.
    double approxRowHeight = responsiveSizeHeight(44.0);

    MapHelperProvider mapHelperProvider = context.read<MapHelperProvider>();
    List<(String, String, double, String)> routeDetails = buildTravelDetails(
      mapHelperProvider.getSuggestedShortestPaths,
      mapHelperProvider.getSelectedRouteId,
    );
    (double, double) fares = computeFareTotalForRoute(
      mapHelperProvider.getSuggestedShortestPaths,
      mapHelperProvider.getSelectedRouteId,
    );

    final bool needsScroll =
        (routeDetails.length * approxRowHeight) > maxListHeight / 2;

    Widget routeList = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, (name, hexcolor, value, fare))
            in routeDetails.indexed) ...[
          if (i > 0)
            Container(
              height: responsiveSizeHeight(2),
              color: Colors.grey.shade400,
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(responsiveSizeHeight(5)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          (name == "Walk")
                              ? Icon(
                                  Icons.directions_walk,
                                  color: hexToColor(hexcolor),
                                  size: responsiveSizeHeight(24),
                                )
                              : (name == "Tricycle")
                              ? ImageIcon(
                                  AssetImage('assets/img/tricycle-icon.png'),
                                  size: responsiveSizeHeight(24),
                                  color: hexToColor(hexcolor),
                                )
                              : ImageIcon(
                                  AssetImage('assets/img/jeepney-icon.png'),
                                  size: responsiveSizeHeight(24),
                                  color: hexToColor(hexcolor),
                                ),
                          SizedBox(width: responsiveSizeWidth(5)),
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: responsiveSizeHeight(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (fare.isNotEmpty) ...[
                        SizedBox(height: responsiveSizeHeight(5)),
                        Container(
                          color: Colors.grey.shade400,
                          width: double.infinity,
                          height: responsiveSizeHeight(2),
                        ),
                        SizedBox(height: responsiveSizeHeight(5)),
                        Text(
                          "Fare: $fare",
                          style: TextStyle(
                            fontSize: responsiveSizeHeight(17),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(responsiveSizeHeight(5)),
                  child: Text(
                    formatDistance(value),
                    style: TextStyle(fontSize: responsiveSizeHeight(20)),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              Container(
                color: Colors.grey.shade900,
                height: responsiveSizeHeight(2),
              ),
            ],
          ),
        ],
      ],
    );

    if (needsScroll) {
      routeList = ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.black, Colors.transparent],
            stops: [0.0, 0.85, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(child: routeList),
        ),
      );
      routeList = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxListHeight),
        child: routeList,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min, // don't force full height
      children: [
        routeList,
        Container(color: Colors.black, height: responsiveSizeHeight(2)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(5),
                child: Row(
                  children: [
                    ImageIcon(
                      AssetImage('assets/img/peso.png'),
                      size: responsiveSizeHeight(24),
                      color: Colors.black,
                    ),
                    SizedBox(width: responsiveSizeWidth(5)),
                    Flexible(
                      child: Text(
                        "Fare Total",
                        style: TextStyle(fontSize: responsiveSizeHeight(20)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(5),
                child: Text(
                  "${fares.$1.toStringAsFixed(2)} ₱",
                  style: TextStyle(fontSize: responsiveSizeHeight(20)),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(5),
                child: Row(
                  children: [
                    ImageIcon(
                      AssetImage('assets/img/peso.png'),
                      size: responsiveSizeHeight(24),
                      color: Colors.black,
                    ),
                    SizedBox(width: responsiveSizeWidth(5)),
                    Flexible(
                      child: Text(
                        "Fare (Discounted)",
                        style: TextStyle(fontSize: responsiveSizeHeight(20)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(5),
                child: Text(
                  "${fares.$2.toStringAsFixed(2)} ₱",
                  style: TextStyle(fontSize: responsiveSizeHeight(20)),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
