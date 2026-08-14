import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/globals/functions/system/permissions.dart';
import 'package:sakenph/globals/functions/utils_responsiveness.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_search_details.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

/// When pressed, it will get the user's current location and passes it to [SystemVariablesProvider]
/// as origin location reference.
///
/// Stateful Widget is used to add color change tap animation
class UseCurrentLocationButton extends StatefulWidget {
  @override
  State<UseCurrentLocationButton> createState() =>
      _UseCurrentLocationButtonState();
}

class _UseCurrentLocationButtonState extends State<UseCurrentLocationButton> {
  bool _showColor = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: responsiveSizeHeight(16)),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            color: _showColor ? Colors.grey.shade300 : Colors.transparent,
            child: GestureDetector(
              onTap: () async {
                bool locationSet = await handleLocationPermission(context);
                if (!locationSet) return;
                setState(() {
                  _showColor = true;
                });
                SearchDetailsProvider searchDetailsProvider = context
                    .read<SearchDetailsProvider>();
                MapHelperProvider mapHelperProvider = context
                    .read<MapHelperProvider>();
                SystemVariablesProvider systemVariablesProvider = context
                    .read<SystemVariablesProvider>();
                mapHelperProvider.useCurrentUserGeoLocAsOrigin();
                systemVariablesProvider.setAppCurrentState =
                    SystemState.gatheringToLoc;
                searchDetailsProvider.requestFocusTowardsLocTextfield();

                searchDetailsProvider.setFromLocTextfieldText =
                    "Your Current Location";
                await Future.delayed(Duration(milliseconds: 100));
                setState(() {
                  _showColor = false;
                });
              },
              child: Container(
                width: responsiveSizeWidth(
                  MediaQuery.sizeOf(context).width * 0.8,
                  500,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black,
                    width: responsiveSizeWidth(1),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: responsiveSizeHeight(16),
                  vertical: responsiveSizeHeight(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: responsiveSizeHeight(20),
                      color: Colors.black87,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Press to use your location",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: responsiveSizeHeight(17),
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
