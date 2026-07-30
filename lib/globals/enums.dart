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

  /// If the backend request fails, it will display a message to the user that the request failed.
  backendRequestFail,

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

  /// This state is achieved by the user long-pressing the map while in the state that's not related to
  /// peeking route, user currently travelling and other states that allow map interaction while having
  /// the search features disabled.
  ///
  /// This state will also create buttons that allow the user to decide if they will use this location
  /// as their source/destination
  confirmingLocationSelection,
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

  /// By quickly pressing a route in route selection and pressing back, the crash for replacing an existing
  /// source & layer to crash the app is possible
  routeSelection,
}

/// Used at <code>provider_search_details.dart</code>
enum SearchFieldType { from, to }
