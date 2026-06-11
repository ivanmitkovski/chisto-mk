import 'package:feature_home/src/data/map_realtime/map_sync_inline_notice.dart';
import 'package:feature_home/src/presentation/providers/map_sites_notifier.dart';

/// Minimum time a sync banner must be visible before a recovery toast is shown.
const Duration kMapUpdatedToastMinBannerVisible = Duration(seconds: 2);

/// Minimum interval between consecutive map-updated toasts.
const Duration kMapUpdatedToastCooldown = Duration(seconds: 60);

/// Whether to show the "map updated" success toast after a sync notice clears.
///
/// The toast is intentionally narrow: only after a data-problem banner
/// ([MapSyncInlineNoticeKind.liveUpdatesDelayed] or [offlineCached]) was
/// visible long enough and a real network sync resolved it while the map tab
/// is on screen.
bool shouldShowMapUpdatedToast({
  required MapSitesState? previous,
  required MapSitesState next,
  required DateTime? syncNoticeVisibleSince,
  required DateTime? lastMapUpdatedToastAt,
  required bool isMapTabActive,
  required bool isMapTabTickerEnabled,
  DateTime? now,
  Duration minBannerVisible = kMapUpdatedToastMinBannerVisible,
  Duration toastCooldown = kMapUpdatedToastCooldown,
}) {
  final MapSyncInlineNotice? previousNotice = previous?.syncNotice;
  if (previousNotice == null) {
    return false;
  }
  if (next.syncNotice != null || next.loadError != null || next.sites.isEmpty) {
    return false;
  }
  if (!isMapTabActive || !isMapTabTickerEnabled) {
    return false;
  }

  switch (previousNotice.kind) {
    case MapSyncInlineNoticeKind.liveUpdatesDelayed:
    case MapSyncInlineNoticeKind.offlineCached:
      break;
    case MapSyncInlineNoticeKind.connectionUnstable:
      return false;
  }

  final DateTime? lastSync = next.lastSuccessfulSyncAt;
  if (lastSync == null ||
      lastSync == previous?.lastSuccessfulSyncAt ||
      next.isUsingPersistedFallback) {
    return false;
  }

  final DateTime resolvedNow = now ?? DateTime.now();
  if (syncNoticeVisibleSince == null ||
      resolvedNow.difference(syncNoticeVisibleSince) < minBannerVisible) {
    return false;
  }

  if (lastMapUpdatedToastAt != null &&
      resolvedNow.difference(lastMapUpdatedToastAt) < toastCooldown) {
    return false;
  }

  return true;
}
