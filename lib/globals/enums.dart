enum SystemStateEnum { gatheringFromLoc }

/// To easily track where all the debouncers are. If strings alone are used to set
/// debouncer ids, it will be a hassle to track them down even if the developers
/// use their IDEs.
///
/// Brief summary of why these are used will be written at the top of the enum value.
enum DebounceIdEnum {
  /// Uses Nominatim API to get place suggestions based on provided value
  nominatim_fromLocationSearch,
}
