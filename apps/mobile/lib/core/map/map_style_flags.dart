/// Compile-time and runtime flags for map styling / vector overlay (Phase 2.4 wiring).
class MapStyleFlags {
  MapStyleFlags._();

  /// When true, clients may request MVT overlay (`MAP_TILE_FORMAT_VECTOR` on API).
  static const bool vectorOverlayFromDefine = bool.fromEnvironment(
    'MAP_VECTOR_OVERLAY',
    defaultValue: false,
  );
}
