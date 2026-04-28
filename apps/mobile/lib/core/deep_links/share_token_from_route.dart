import 'package:chisto_mobile/core/deep_links/deep_link_router.dart';

String? shareTokenFromDeepLinkRoute(DeepLinkRoute? route) {
  switch (route) {
    case DeepLinkSiteDetail(:final String? shareToken):
      return shareToken;
    case DeepLinkHomeMapFocus(:final String? shareToken):
      return shareToken;
    default:
      return null;
  }
}
