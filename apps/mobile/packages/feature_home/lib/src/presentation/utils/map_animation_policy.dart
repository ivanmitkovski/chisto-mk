/// Graded map animation policy for dense site sets.
enum MapAnimationLevel {
  /// Full springs, entrances, cluster pulse.
  full,

  /// Geographic motion only; skip entrance/pulse.
  motionOnly,

  /// Static markers (accessibility / very dense).
  static,
}

MapAnimationLevel mapAnimationLevelForSiteCount(int count) {
  if (count <= 120) {
    return MapAnimationLevel.full;
  }
  if (count <= 220) {
    return MapAnimationLevel.motionOnly;
  }
  return MapAnimationLevel.static;
}

bool mapReduceAnimations({
  required bool disableAnimations,
  required int filteredSiteCount,
}) {
  if (disableAnimations) {
    return true;
  }
  return mapAnimationLevelForSiteCount(filteredSiteCount) ==
      MapAnimationLevel.static;
}

bool mapSkipEntranceAnimations({
  required bool disableAnimations,
  required int filteredSiteCount,
}) {
  if (disableAnimations) {
    return true;
  }
  final MapAnimationLevel level = mapAnimationLevelForSiteCount(
    filteredSiteCount,
  );
  return level != MapAnimationLevel.full;
}
