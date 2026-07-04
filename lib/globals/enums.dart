/// To restrict logic choices when planning and developing what to display in the
/// Foreground and Background widgets at the main page.
enum SystemState {
  /// It will only display the search results done in the FromLoc textfield
  gatheringFromLoc,

  /// It will only display the search results done in the ToLoc textfield
  gatheringToLoc,

  /// It will show a loading animated widget. Made to indirectly tell the user to wait for backend response.
  /// As of this writing, it doesn't handle backend errors
  waitingForBackendResponse,

  /// Displays the suggested routes received from backend
  showSuggestedRoutes,

  /// Adjust background widget visibility so the user can peek at where the route is placed.
  /// The 2 textfields will be hidden while the app is in this state
  peekAtRoute,

  /// It removes the visibility of the background widget
  hideWidgets,

  /// When this state is achieved, origin and destination location is now identified. It will
  /// now start the looping job of checking
  isCurrentlyTravelling,

  /// TODO: THIS NEEDS DEV
  confirmationForTerminatingTravel,
}

/// To easily track where all the debouncers are. If strings alone are used to set
/// debouncer ids, it will be a hassle to track them down even if the developers
/// use their IDEs.
///
/// Brief summary of why these are used will be written at the top of the enum value.
enum DebounceId {
  /// Uses Nominatim API to get place suggestions based on provided value
  nominatim_fromLocationSearch,
  nominatim_toLocationSearch,
  getCurrentLocation,
}

/// Used at <code>provider_search_details.dart</code>
enum SearchFieldType { from, to }
