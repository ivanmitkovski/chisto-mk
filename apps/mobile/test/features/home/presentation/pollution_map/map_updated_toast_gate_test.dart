import 'package:feature_home/src/data/map_realtime/map_sync_inline_notice.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/pollution_map/map_updated_toast_gate.dart';
import 'package:feature_home/src/presentation/providers/map_sites_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_pollution_site.dart';

MapSitesState _state({
  MapSyncInlineNotice? syncNotice,
  DateTime? lastSuccessfulSyncAt,
  bool isUsingPersistedFallback = false,
}) {
  return MapSitesState(
    sites: <PollutionSite>[buildTestPollutionSite(id: 'site-1')],
    syncNotice: syncNotice,
    lastSuccessfulSyncAt: lastSuccessfulSyncAt,
    isUsingPersistedFallback: isUsingPersistedFallback,
  );
}

void main() {
  final DateTime t0 = DateTime(2026, 6, 11, 12, 0, 0);
  final DateTime t1 = t0.add(const Duration(seconds: 3));
  final DateTime tSyncBefore = t0.subtract(const Duration(minutes: 5));
  final DateTime tSyncAfter = t0;

  group('shouldShowMapUpdatedToast', () {
    test('returns true for liveUpdatesDelayed recovery with fresh sync', () {
      expect(
        shouldShowMapUpdatedToast(
          previous: _state(
            syncNotice: const MapSyncInlineNotice.liveUpdatesDelayed(),
            lastSuccessfulSyncAt: tSyncBefore,
          ),
          next: _state(lastSuccessfulSyncAt: tSyncAfter),
          syncNoticeVisibleSince: t0,
          lastMapUpdatedToastAt: null,
          isMapTabActive: true,
          isMapTabTickerEnabled: true,
          now: t1,
        ),
        isTrue,
      );
    });

    test('returns true for offlineCached recovery with fresh sync', () {
      expect(
        shouldShowMapUpdatedToast(
          previous: _state(
            syncNotice: const MapSyncInlineNotice.offlineCached(),
            lastSuccessfulSyncAt: tSyncBefore,
          ),
          next: _state(lastSuccessfulSyncAt: tSyncAfter),
          syncNoticeVisibleSince: t0,
          lastMapUpdatedToastAt: null,
          isMapTabActive: true,
          isMapTabTickerEnabled: true,
          now: t1,
        ),
        isTrue,
      );
    });

    test('suppresses connectionUnstable recovery', () {
      expect(
        shouldShowMapUpdatedToast(
          previous: _state(
            syncNotice: const MapSyncInlineNotice.connectionUnstable(),
            lastSuccessfulSyncAt: tSyncBefore,
          ),
          next: _state(lastSuccessfulSyncAt: tSyncAfter),
          syncNoticeVisibleSince: t0,
          lastMapUpdatedToastAt: null,
          isMapTabActive: true,
          isMapTabTickerEnabled: true,
          now: t1,
        ),
        isFalse,
      );
    });

    test('suppresses when lastSuccessfulSyncAt unchanged', () {
      expect(
        shouldShowMapUpdatedToast(
          previous: _state(
            syncNotice: const MapSyncInlineNotice.liveUpdatesDelayed(),
            lastSuccessfulSyncAt: tSyncBefore,
          ),
          next: _state(lastSuccessfulSyncAt: tSyncBefore),
          syncNoticeVisibleSince: t0,
          lastMapUpdatedToastAt: null,
          isMapTabActive: true,
          isMapTabTickerEnabled: true,
          now: t1,
        ),
        isFalse,
      );
    });

    test('suppresses persisted fallback recovery', () {
      expect(
        shouldShowMapUpdatedToast(
          previous: _state(
            syncNotice: const MapSyncInlineNotice.offlineCached(),
            lastSuccessfulSyncAt: tSyncBefore,
          ),
          next: _state(
            lastSuccessfulSyncAt: tSyncAfter,
            isUsingPersistedFallback: true,
          ),
          syncNoticeVisibleSince: t0,
          lastMapUpdatedToastAt: null,
          isMapTabActive: true,
          isMapTabTickerEnabled: true,
          now: t1,
        ),
        isFalse,
      );
    });

    test('suppresses when banner visible less than minimum', () {
      expect(
        shouldShowMapUpdatedToast(
          previous: _state(
            syncNotice: const MapSyncInlineNotice.liveUpdatesDelayed(),
            lastSuccessfulSyncAt: tSyncBefore,
          ),
          next: _state(lastSuccessfulSyncAt: tSyncAfter),
          syncNoticeVisibleSince: t1.subtract(const Duration(milliseconds: 500)),
          lastMapUpdatedToastAt: null,
          isMapTabActive: true,
          isMapTabTickerEnabled: true,
          now: t1,
        ),
        isFalse,
      );
    });

    test('suppresses within cooldown window', () {
      expect(
        shouldShowMapUpdatedToast(
          previous: _state(
            syncNotice: const MapSyncInlineNotice.liveUpdatesDelayed(),
            lastSuccessfulSyncAt: tSyncBefore,
          ),
          next: _state(lastSuccessfulSyncAt: tSyncAfter),
          syncNoticeVisibleSince: t0,
          lastMapUpdatedToastAt: t1.subtract(const Duration(seconds: 30)),
          isMapTabActive: true,
          isMapTabTickerEnabled: true,
          now: t1,
        ),
        isFalse,
      );
    });

    test('suppresses when map tab inactive', () {
      expect(
        shouldShowMapUpdatedToast(
          previous: _state(
            syncNotice: const MapSyncInlineNotice.liveUpdatesDelayed(),
            lastSuccessfulSyncAt: tSyncBefore,
          ),
          next: _state(lastSuccessfulSyncAt: tSyncAfter),
          syncNoticeVisibleSince: t0,
          lastMapUpdatedToastAt: null,
          isMapTabActive: false,
          isMapTabTickerEnabled: true,
          now: t1,
        ),
        isFalse,
      );
    });

    test('suppresses when map tab ticker disabled (offstage shell branch)', () {
      expect(
        shouldShowMapUpdatedToast(
          previous: _state(
            syncNotice: const MapSyncInlineNotice.liveUpdatesDelayed(),
            lastSuccessfulSyncAt: tSyncBefore,
          ),
          next: _state(lastSuccessfulSyncAt: tSyncAfter),
          syncNoticeVisibleSince: t0,
          lastMapUpdatedToastAt: null,
          isMapTabActive: true,
          isMapTabTickerEnabled: false,
          now: t1,
        ),
        isFalse,
      );
    });

    test('suppresses when previous notice was null', () {
      expect(
        shouldShowMapUpdatedToast(
          previous: _state(lastSuccessfulSyncAt: tSyncBefore),
          next: _state(lastSuccessfulSyncAt: tSyncAfter),
          syncNoticeVisibleSince: t0,
          lastMapUpdatedToastAt: null,
          isMapTabActive: true,
          isMapTabTickerEnabled: true,
          now: t1,
        ),
        isFalse,
      );
    });

    test('suppresses when next still has notice or load error or empty sites', () {
      expect(
        shouldShowMapUpdatedToast(
          previous: _state(
            syncNotice: const MapSyncInlineNotice.liveUpdatesDelayed(),
            lastSuccessfulSyncAt: tSyncBefore,
          ),
          next: _state(
            syncNotice: const MapSyncInlineNotice.liveUpdatesDelayed(),
            lastSuccessfulSyncAt: tSyncAfter,
          ),
          syncNoticeVisibleSince: t0,
          lastMapUpdatedToastAt: null,
          isMapTabActive: true,
          isMapTabTickerEnabled: true,
          now: t1,
        ),
        isFalse,
      );
    });
  });
}
