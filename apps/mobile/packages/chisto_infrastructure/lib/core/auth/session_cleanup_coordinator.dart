import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/profile/profile_avatar_sync.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/reports_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:feature_auth/src/data/user_home_location_store.dart';
import 'package:feature_auth/src/domain/ports/auth_push_port.dart';
import 'package:feature_events/src/data/chat/outbox/chat_outbox_store.dart';
import 'package:feature_events/src/data/check_in_local_cache.dart';
import 'package:feature_events/src/data/discovery_analytics.dart';
import 'package:feature_events/src/data/event_calendar_added_store.dart';
import 'package:feature_events/src/data/event_feedback_local_cache.dart';
import 'package:feature_events/src/data/events_discovery_preferences.dart';
import 'package:feature_events/src/data/events_local_cache.dart';
import 'package:feature_events/src/data/field_mode_queue.dart';
import 'package:feature_home/src/data/engagement_outbox_store.dart';
import 'package:feature_home/src/data/map_search_recents_store.dart';
import 'package:feature_home/src/data/sites_local_cache.dart';
import 'package:feature_notifications/src/data/pending_chat_reply_store.dart';
import 'package:feature_notifications/src/data/push_background_pending_store.dart';
import 'package:feature_reports/src/data/outbox/report_draft_photo_store.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_repository.dart'
    show ReportOutboxRepository, SqfliteReportOutboxRepository;
import 'package:shared_preferences/shared_preferences.dart';

/// Best-effort wipe of user-specific local state on logout / session loss.
class SessionCleanupCoordinator {
  SessionCleanupCoordinator({
    required SharedPreferences preferences,
    ProfileAvatarSync avatarSync = const NoOpProfileAvatarSync(),
    ReportDraftPhotoStore Function()? reportDraftPhotoStoreFactory,
    Future<ReportOutboxRepository> Function()? openReportOutboxRepository,
  }) : _preferences = preferences,
       _avatarSync = avatarSync,
       _reportDraftPhotoStoreFactory =
           reportDraftPhotoStoreFactory ?? ReportDraftPhotoStore.new,
       _openReportOutboxRepository =
           openReportOutboxRepository ?? SqfliteReportOutboxRepository.open;

  final SharedPreferences _preferences;
  final ProfileAvatarSync _avatarSync;
  final ReportDraftPhotoStore Function() _reportDraftPhotoStoreFactory;
  final Future<ReportOutboxRepository> Function() _openReportOutboxRepository;

  Future<void> clearLocalPii({AuthPushPort? pushService}) async {
    _avatarSync.clearAll();
    await ChatOutboxStore.shared.clearAll();
    await const EventsLocalCache().clear();
    await _bestEffort(_clearReportOutboxAndDraftPhotos);
    await _bestEffort(() => const EventsDiscoveryPreferences().clear());
    await _bestEffort(EventCalendarAddedStore.clear);
    await _bestEffort(() => SitesLocalCache().clearFeedAndMapSnapshots());
    await _bestEffort(EngagementOutboxStore.instance.clearAll);
    await _bestEffort(FieldModeQueue.instance.clearAll);
    await _bestEffort(PushBackgroundPendingStore.clearAll);
    await _bestEffort(() async {
      final String? userId = tryReadRoot(authStateProvider)?.userId;
      await UserHomeLocationStore.clearAllForSession(
        _preferences,
        userId: userId,
      );
    });
    await _bestEffort(() => MapSearchRecentsStore.clear(_preferences));
    await _bestEffort(() => const CheckInLocalCache().clear());
    await _bestEffort(() => const EventFeedbackLocalCache().clear());
    await _bestEffort(PendingChatReplyStore.clear);
    await _bestEffort(DiscoveryAnalytics.clearUserConsent);
    await pushService?.teardownFirebaseListeners();
  }

  Future<void> _clearReportOutboxAndDraftPhotos() async {
    final AppBootstrap? bootstrap = tryReadRoot(appBootstrapProvider);
    if (bootstrap != null && bootstrap.isInitialized) {
      await readRoot(reportDraftPhotoStoreProvider).clearAll();
      await readRoot(reportOutboxRepositoryProvider).wipeAll();
      return;
    }

    await _reportDraftPhotoStoreFactory().clearAll();
    final ReportOutboxRepository repo = await _openReportOutboxRepository();
    try {
      await repo.wipeAll();
    } finally {
      await repo.close();
    }
  }

  Future<void> _bestEffort(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      /* best effort */
    }
  }
}
