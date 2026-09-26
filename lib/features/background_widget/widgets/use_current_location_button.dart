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

  void _onTap(
    SearchDetailsProvider searchDetailsProvider,
    MapHelperProvider mapHelperProvider,
    SystemVariablesProvider systemVariablesProvider,
  ) async {
    // reattempt to get location permissions
    bool locationSet = await handleLocationPermission(context);
    if (!locationSet) return;
    // show color temporarily to make the user feel like they actually pressed a button
    setState(() {
      _showColor = true;
    });
    searchDetailsProvider.setHasObtainedFromLocAtLeastOnce = true;
    // set the value to true since this is a unique input type aside from the usual manual loc name typing
    searchDetailsProvider.setIsInputSpecial_fromLoc = true;
    // use the user's current geoloc as from location
    mapHelperProvider.useCurrentUserGeoLocAsOrigin();
    // move the state to gatheringToLoc so the transition to using the to location textfield would be smooth
    systemVariablesProvider.setAppCurrentState = SystemState.gatheringToLoc;
    // move the focus to the second textfield
    searchDetailsProvider.requestFocusTowardsLocTextfield();
    // rename the hint text to this. modifying the hint text was used because relying on modifying textfield text was introducing complications
    searchDetailsProvider.setFromLocTextfieldHintText =
        "Your Current GeoLocation";
    // cleanup to be sure
    searchDetailsProvider.getFromLocTextController.text = "";
    // revert the button back to its original color which is none/white
    await Future.delayed(Duration(milliseconds: 100));
    setState(() {
      _showColor = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    SearchDetailsProvider searchDetailsProvider = context
        .read<SearchDetailsProvider>();
    MapHelperProvider mapHelperProvider = context.read<MapHelperProvider>();
    SystemVariablesProvider systemVariablesProvider = context
        .read<SystemVariablesProvider>();
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
                _onTap(
                  searchDetailsProvider,
                  mapHelperProvider,
                  systemVariablesProvider,
                );
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
