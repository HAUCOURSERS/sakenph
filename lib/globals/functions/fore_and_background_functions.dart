import 'package:flutter/material.dart';
import 'package:sakenph/api/backend_service.dart';
import 'package:sakenph/classes/nominatim_response.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_search_details.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

/// Passing the needed information would save the information for later use.
void processLocationInformation(
  SearchFieldType searchFieldType,
  MapHelperProvider mapHelperProvider,
  SearchDetailsProvider searchDetailsProvider,
  SystemVariablesProvider systemVariablesProvider,
  BuildContext context,
  NominatimPlace nomiPlace,

  /// Some callers have this false because having this on in certain circumstances is problematic.
  bool shouldExecuteComputation,
) {
  switch (searchFieldType) {
    case SearchFieldType.from:
      // save fromloc nominatim details
      mapHelperProvider.setFromLocationDetails = nomiPlace;
      // in order for the destination textfield to show up for the rest of the app runtime
      searchDetailsProvider.setHasObtainedFromLocAtLeastOnce = true;
      // switch state to gatheringToLoc
      systemVariablesProvider.setAppCurrentState = SystemState.gatheringToLoc;
      // set textfield name to reflect the display name of the selected place
      searchDetailsProvider.setFromLocTextfieldText = nomiPlace.name;
      // move focus to the next textfield
      searchDetailsProvider.requestFocusTowardsLocTextfield();
      break;
    case SearchFieldType.to:
      // save toloc nominatim details
      mapHelperProvider.setToLocationDetails = nomiPlace;
      // start computing routes between fromloc to toloc
      if (shouldExecuteComputation) startComputingForRoutes(context);
      // set textfield name to reflect the display name of the selected place
      searchDetailsProvider.setToLocTextfieldText = nomiPlace.name;
      // unfocus from the textfield since it's no longer needed
      searchDetailsProvider.unfocusFromLocTextfield();
      break;
  }
}
