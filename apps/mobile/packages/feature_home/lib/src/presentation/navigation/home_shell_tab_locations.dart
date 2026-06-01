/// Maps bottom-nav index to shell location.
String homeShellTabIndexToLocation(int index) {
  switch (index.clamp(0, 3)) {
    case 1:
      return '/reports';
    case 2:
      return '/map';
    case 3:
      return '/events';
    case 0:
    default:
      return '/feed';
  }
}

int homeShellLocationToTabIndex(String location) {
  if (location.startsWith('/reports')) {
    return 1;
  }
  if (location.startsWith('/map')) {
    return 2;
  }
  if (location.startsWith('/events')) {
    return 3;
  }
  return 0;
}

/// Full-screen feed sub-routes where the tab bar and central FAB should not show.
bool homeShellShouldHideBottomBar(Uri uri) {
  final List<String> s = uri.pathSegments;
  // `/feed/:siteId`, `/feed/:siteId/comments`, `/feed/:siteId/upvoters`
  return s.length >= 2 && s[0] == 'feed';
}
