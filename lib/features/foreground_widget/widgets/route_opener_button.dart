import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

/// Appears if the user has queried for routes and valid routes showed up. Relying
/// on the search button is useless since it's hard to press on screen
class RouteOpenerButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () {
          context.read<SystemVariablesProvider>().setAppCurrentState =
              SystemState.showSuggestedRoutes;
          context
                  .read<SystemVariablesProvider>()
                  .setBackgroundWidgetVisibility =
              true;
        },
        child: Container(
          width: responsiveSizeWidth(
            MediaQuery.sizeOf(context).width * 0.75,
            500,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: responsiveSizeHeight(16),
            vertical: responsiveSizeHeight(14),
          ),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 176, 221, 255),
            border: Border.all(width: responsiveSizeHeight(1)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.explore,
                size: responsiveSizeHeight(20),
                color: Colors.black87,
              ),
              SizedBox(width: 8),
              Text(
                "View Searched Routes",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: responsiveSizeHeight(16),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
