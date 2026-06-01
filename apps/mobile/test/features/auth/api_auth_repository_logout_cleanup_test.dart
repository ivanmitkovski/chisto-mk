import 'dart:io';

import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/auth/session_cleanup_coordinator.dart';
import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/profile/profile_avatar_sync.dart';
import 'package:chisto_infrastructure/core/storage/secure_token_storage.dart';
import 'package:feature_auth/src/data/api_auth_repository.dart';
import 'package:feature_auth/src/data/eula_acceptance_store.dart';
import 'package:feature_auth/src/data/user_home_location_store.dart';
import 'package:feature_events/src/data/check_in_local_cache.dart';
import 'package:feature_events/src/data/discovery_analytics.dart';
import 'package:feature_events/src/data/event_calendar_added_store.dart';
import 'package:feature_events/src/data/event_feedback_local_cache.dart';
import 'package:feature_events/src/data/events_discovery_preferences.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_home/src/data/map_search_recents_store.dart';
import 'package:feature_home/src/data/sites_local_cache.dart';
import 'package:feature_notifications/src/data/pending_chat_reply_store.dart';
import 'package:feature_reports/src/data/outbox/report_draft_photo_store.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_database.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_entry.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_repository.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

EcoEvent _calendarEvent({required String id}) {
  final DateTime day = DateTime(2026, 5, 29, 7, 30);
  return EcoEvent(
    id: id,
    title: 'Cleanup',
    description: '',
    category: EcoEventCategory.generalCleanup,
    siteId: 'site-1',
    siteName: 'Park',
    siteImageUrl: '',
    siteDistanceKm: 1,
    organizerId: 'org-1',
    organizerName: 'Org',
    date: DateTime(day.year, day.month, day.day),
    startTime: EventTime(hour: day.hour, minute: day.minute),
    endTime: const EventTime(hour: 23, minute: 59),
    participantCount: 1,
    status: EcoEventStatus.upcoming,
    createdAt: DateTime(2026, 1, 1),
  );
}

Future<Database> _openLogoutTestOutboxDb() async {
  final Directory dir = await Directory.systemTemp.createTemp('logout_outbox_');
  final String path = p.join(dir.path, 'outbox.db');
  final Database db = await openDatabase(
    path,
    version: 3,
    onCreate: (Database db, int version) async {
      await db.execute('''
CREATE TABLE ${ReportOutboxDatabase.tableOutbox} (
  id TEXT NOT NULL PRIMARY KEY,
  idempotency_key TEXT NOT NULL UNIQUE,
  draft_json TEXT NOT NULL,
  state TEXT NOT NULL,
  submit_requested INTEGER NOT NULL DEFAULT 0,
  media_urls_json TEXT,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  last_error_code TEXT,
  last_error_message TEXT,
  cooldown_until_ms INTEGER,
  report_id TEXT,
  created_at_ms INTEGER NOT NULL,
  updated_at_ms INTEGER NOT NULL,
  current_stage TEXT,
  attempted_stages_json TEXT,
  last_persisted_at_ms INTEGER
)''');
    },
  );
  return db;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiAuthRepository logout cleanup', () {
    late SharedPreferences prefs;
    late ApiAuthRepository repo;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      SharedPreferences.setMockInitialValues(<String, Object>{
        kUserHomeLatitudeKey: 41.99,
        kUserHomeLongitudeKey: 21.43,
        kUserHomeLocationLabelKey: 'Skopje',
        'map_search_recent_v1': '["trash"]',
        'events_checkin_sessions_v1': '[]',
        'events_feedback_snapshot_v1': '{}',
        'pending_chat_replies_v1': '[]',
        'discovery_analytics_consent_v1': true,
      });
      prefs = await SharedPreferences.getInstance();
      final AuthState authState = AuthState();
      authState.setAuthenticated(
        userId: 'u1',
        displayName: 'Test',
        accessToken: 'tok',
      );
      repo = ApiAuthRepository(
        client: ApiClient(
          config: AppConfig.dev,
          accessToken: () => authState.accessToken,
          onUnauthorized: () {},
        ),
        authState: authState,
        tokenStorage: SecureTokenStorage(storage: const FlutterSecureStorage()),
        preferences: prefs,
        avatarSync: const NoOpProfileAvatarSync(),
      );
    });

    test('invalidateLocalSession clears PII SharedPreferences', () async {
      await EulaAcceptanceStore(prefs).acceptForUser('u1');
      await repo.invalidateLocalSession();

      expect(prefs.getDouble(kUserHomeLatitudeKey), isNull);
      expect(await EulaAcceptanceStore(prefs).hasAcceptedForUser('u1'), isTrue);
      expect(MapSearchRecentsStore.readSync(prefs), isEmpty);
      expect(await const CheckInLocalCache().readSessions(), isEmpty);
      expect(await DiscoveryAnalytics.readUserConsent(), isFalse);
      expect(await PendingChatReplyStore.peekAll(), isEmpty);
      expect(await const EventFeedbackLocalCache().read('any'), isNull);
    });

    test(
      'invalidateLocalSession clears discovery prefs, calendar marks, and sites cache',
      () async {
        const EventsDiscoveryPreferences discovery =
            EventsDiscoveryPreferences();
        await discovery.writeRecentSearches(<String>['beach']);
        await discovery.writeCalendarViewPreferred(true);
        final EcoEvent event = _calendarEvent(id: 'evt-logout');
        await EventCalendarAddedStore.markAdded(event);
        await prefs.setString(
          SitesLocalCache.feedPersistedCacheKey,
          '{"feeds":{"nearby":{}}}',
        );
        await prefs.setString(
          SitesLocalCache.mapPersistedCacheKey,
          '{"sites":[]}',
        );

        await repo.invalidateLocalSession();

        expect(await discovery.readRecentSearches(), isEmpty);
        expect(await discovery.readCalendarViewPreferred(), isFalse);
        expect(await EventCalendarAddedStore.isMarkedAdded(event), isFalse);
        expect(prefs.getString(SitesLocalCache.feedPersistedCacheKey), isNull);
        expect(prefs.getString(SitesLocalCache.mapPersistedCacheKey), isNull);
      },
    );

    test(
      'invalidateLocalSession wipes report outbox and draft photos',
      () async {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;

        final Database db = await _openLogoutTestOutboxDb();
        final String dbPath = db.path;
        addTearDown(() async => db.close());
        final SqfliteReportOutboxRepository outboxRepo =
            SqfliteReportOutboxRepository(db);
        final int now = DateTime.now().millisecondsSinceEpoch;
        await outboxRepo.insert(
          ReportOutboxEntry(
            id: 'queued-report',
            idempotencyKey: 'idem-queued',
            draft: ReportDraft(),
            title: 'Trash',
            description: 'Near river',
            submitRequested: true,
            state: ReportOutboxState.pending,
            attemptCount: 0,
            createdAtMs: now,
            updatedAtMs: now,
          ),
        );

        final Directory photoRoot = await Directory.systemTemp.createTemp(
          'logout_photos_',
        );
        addTearDown(() async {
          if (await photoRoot.exists()) {
            await photoRoot.delete(recursive: true);
          }
        });
        final File photo = File(p.join(photoRoot.path, 'draft.jpg'));
        await photo.writeAsBytes(<int>[1, 2, 3]);
        final ReportDraftPhotoStore photoStore = ReportDraftPhotoStore(
          rootOverride: photoRoot,
        );
        await photoStore.importPhoto(XFile(photo.path));

        final ApiAuthRepository outboxRepoAuth = ApiAuthRepository(
          client: ApiClient(
            config: AppConfig.dev,
            accessToken: () => null,
            onUnauthorized: () {},
          ),
          authState: AuthState(),
          tokenStorage: SecureTokenStorage(
            storage: const FlutterSecureStorage(),
          ),
          preferences: prefs,
          avatarSync: const NoOpProfileAvatarSync(),
          sessionCleanup: SessionCleanupCoordinator(
            preferences: prefs,
            avatarSync: const NoOpProfileAvatarSync(),
            reportDraftPhotoStoreFactory: () => photoStore,
            openReportOutboxRepository: () async => outboxRepo,
          ),
        );

        await outboxRepoAuth.invalidateLocalSession();

        final Database verifyDb = await openDatabase(dbPath);
        addTearDown(() async => verifyDb.close());
        expect(await SqfliteReportOutboxRepository(verifyDb).countAllRows(), 0);
        var hasManagedPhotos = false;
        if (await photoRoot.exists()) {
          await for (final FileSystemEntity entity in photoRoot.list(
            recursive: true,
          )) {
            if (entity is File) {
              hasManagedPhotos = true;
              break;
            }
          }
        }
        expect(hasManagedPhotos, isFalse);
      },
    );
  });
}
