import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';

const String _prefDarkTiles = 'map_use_dark_tiles';
const String _prefHeatmap = 'map_show_heatmap';
const String _prefRotationLock = 'map_rotation_locked';

class MapUiModeState {
  const MapUiModeState({
    required this.useDarkTiles,
    required this.showHeatmap,
    required this.rotationLocked,
  });

  final bool useDarkTiles;
  final bool showHeatmap;
  final bool rotationLocked;

  MapUiModeState copyWith({
    bool? useDarkTiles,
    bool? showHeatmap,
    bool? rotationLocked,
  }) {
    return MapUiModeState(
      useDarkTiles: useDarkTiles ?? this.useDarkTiles,
      showHeatmap: showHeatmap ?? this.showHeatmap,
      rotationLocked: rotationLocked ?? this.rotationLocked,
    );
  }
}

final mapUiModeNotifierProvider =
    NotifierProvider<MapUiModeNotifier, MapUiModeState>(MapUiModeNotifier.new);

class MapUiModeNotifier extends Notifier<MapUiModeState> {
  @override
  MapUiModeState build() {
    final prefs = ServiceLocator.instance.preferences;
    return MapUiModeState(
      useDarkTiles: prefs.getBool(_prefDarkTiles) ?? false,
      showHeatmap: prefs.getBool(_prefHeatmap) ?? false,
      rotationLocked: prefs.getBool(_prefRotationLock) ?? false,
    );
  }

  Future<void> toggleDarkTiles() async {
    final bool next = !state.useDarkTiles;
    state = state.copyWith(useDarkTiles: next);
    await ServiceLocator.instance.preferences.setBool(_prefDarkTiles, next);
  }

  Future<void> toggleHeatmap() async {
    final bool next = !state.showHeatmap;
    state = state.copyWith(showHeatmap: next);
    await ServiceLocator.instance.preferences.setBool(_prefHeatmap, next);
  }

  Future<void> toggleRotationLock() async {
    final bool next = !state.rotationLocked;
    state = state.copyWith(rotationLocked: next);
    await ServiceLocator.instance.preferences.setBool(_prefRotationLock, next);
  }

  Future<void> setRotationLocked(bool locked) async {
    state = state.copyWith(rotationLocked: locked);
    await ServiceLocator.instance.preferences.setBool(_prefRotationLock, locked);
  }
}
