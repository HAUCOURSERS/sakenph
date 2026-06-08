/// To restrict logic choices when planning and developing what to display in the
/// Foreground and Background widgets at the main page.
enum SystemStateEnum { gatheringFromLoc, gatheringToLoc }

/// To easily track where all the debouncers are. If strings alone are used to set
/// debouncer ids, it will be a hassle to track them down even if the developers
/// use their IDEs.
///
/// Brief summary of why these are used will be written at the top of the enum value.
enum DebounceIdEnum {
  /// Uses Nominatim API to get place suggestions based on provided value
  nominatim_fromLocationSearch,
  nominatim_toLocationSearch,
}
