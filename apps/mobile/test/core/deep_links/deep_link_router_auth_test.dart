import 'package:chisto_infrastructure/core/deep_links/deep_link_router.dart';
import 'package:chisto_infrastructure/core/navigation/app_go_router.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  group('DeepLinkRouter', () {
    late GoRouter router;

    setUpAll(() async {
      await bootstrapWidgetTests();
    });

    setUp(() {
      DeepLinkRouter.resetDedupeForTest();
      router = buildAppGoRouter();
    });

    test('queues deep link for replay after sign-in', () {
      final Uri uri = Uri.parse(
        'https://chisto.mk/app/events/detail/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      );
      DeepLinkRouter.handleUri(router, uri, isAuthenticated: false);
      expect(DeepLinkRouter.pendingAuthenticatedUriForTest, uri);
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.signIn);

      DeepLinkRouter.replayPendingAuthenticatedRoute(router);
      expect(
        router.routeInformationProvider.value.uri.path,
        '${AppRoutes.eventsDetail}/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      );
      expect(DeepLinkRouter.pendingAuthenticatedUriForTest, isNull);
    });

    test('routes unauthenticated event-detail to sign-in', () {
      final bool handled = DeepLinkRouter.handleUri(
        router,
        Uri.parse(
          'https://chisto.mk/app/events/detail/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        ),
        isAuthenticated: false,
      );
      expect(handled, isTrue);
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.signIn);
    });

    test('routes unauthenticated new-report to sign-in', () {
      DeepLinkRouter.handleUri(
        router,
        Uri.parse('chisto://app/reports/new'),
        isAuthenticated: false,
      );
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.signIn);
    });

    test('deduplicates identical URIs within the dedupe window', () {
      final Uri uri = Uri.parse('chisto://app/reports/new');
      DeepLinkRouter.handleUri(router, uri, isAuthenticated: true);
      DeepLinkRouter.handleUri(router, uri, isAuthenticated: true);
      DeepLinkRouter.handleUri(router, uri, isAuthenticated: true);
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.newReport,
      );
    });
  });
}
