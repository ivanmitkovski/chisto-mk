/// Payload for the slim sync strip under the map toolbar (localized in the banner widget).
enum MapSyncInlineNoticeKind {
  liveUpdatesDelayed,
  connectionUnstable,
  offlineCached,
}

class MapSyncInlineNotice {
  const MapSyncInlineNotice._(this.kind, this.cachedAt);

  const MapSyncInlineNotice.liveUpdatesDelayed()
      : this._(MapSyncInlineNoticeKind.liveUpdatesDelayed, null);

  const MapSyncInlineNotice.connectionUnstable()
      : this._(MapSyncInlineNoticeKind.connectionUnstable, null);

  /// [cachedAt] is when the cached map payload was written (may be null when unknown).
  const MapSyncInlineNotice.offlineCached({DateTime? cachedAt})
      : this._(MapSyncInlineNoticeKind.offlineCached, cachedAt);

  final MapSyncInlineNoticeKind kind;
  final DateTime? cachedAt;

  @override
  bool operator ==(Object other) =>
      other is MapSyncInlineNotice &&
      other.kind == kind &&
      other.cachedAt == cachedAt;

  @override
  int get hashCode => Object.hash(kind, cachedAt);
}
