import 'package:chisto_infrastructure/core/providers/home_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:feature_home/src/data/site_issue_report_repository.dart';
import 'package:feature_home/src/domain/models/site_report_reason.dart';
import 'package:feature_home/src/domain/repositories/sites_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingSitesRepository implements SitesRepository {
  final List<
    ({String siteId, String feedbackType, Map<String, dynamic>? metadata})
  >
  calls =
      <
        ({String siteId, String feedbackType, Map<String, dynamic>? metadata})
      >[];

  @override
  Future<void> submitFeedFeedback(
    String siteId, {
    required String feedbackType,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) async {
    calls.add((siteId: siteId, feedbackType: feedbackType, metadata: metadata));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingSitesRepository sitesRepository;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    sitesRepository = _RecordingSitesRepository();
    container = ProviderContainer(
      overrides: <Override>[
        sitesRepositoryProvider.overrideWithValue(sitesRepository),
      ],
    );
    setRootProviderContainer(container);
  });

  tearDown(() {
    clearRootProviderContainer();
    container.dispose();
  });

  test('hasReported is false until site is submitted', () async {
    final SiteIssueReportRepository repo = SiteIssueReportRepository();

    expect(await repo.hasReported('site-1'), isFalse);
  });

  test('submitReport posts feedback and persists reported site id', () async {
    final SiteIssueReportRepository repo = SiteIssueReportRepository();

    await repo.submitReport(
      siteId: 'site-42',
      reason: SiteReportReason.wrongLocation,
      details: '  Pin is off by 200m  ',
    );

    expect(sitesRepository.calls, hasLength(1));
    expect(sitesRepository.calls.single.siteId, 'site-42');
    expect(sitesRepository.calls.single.feedbackType, 'misleading');
    expect(sitesRepository.calls.single.metadata, <String, dynamic>{
      'source': 'report_issue',
      'reason': 'wrongLocation',
      'details': 'Pin is off by 200m',
    });
    expect(await repo.hasReported('site-42'), isTrue);
    expect(await repo.hasReported('site-other'), isFalse);
  });

  test('submitReport omits blank details from metadata', () async {
    final SiteIssueReportRepository repo = SiteIssueReportRepository();

    await repo.submitReport(
      siteId: 'site-7',
      reason: SiteReportReason.spam,
      details: '   ',
    );

    expect(sitesRepository.calls.single.metadata, <String, dynamic>{
      'source': 'report_issue',
      'reason': 'spam',
    });
  });
}
