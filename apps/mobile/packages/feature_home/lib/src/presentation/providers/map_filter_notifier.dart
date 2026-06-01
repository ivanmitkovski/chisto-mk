import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/widgets/map/map_status_codes.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local map filters (site workflow status, pollution type, optional geographic area).
class MapFilterState {
  const MapFilterState({
    required this.activeStatuses,
    required this.activePollutionTypes,
    this.geoAreaId,
    this.includeArchived = false,
  });

  final Set<String> activeStatuses;
  final Set<String> activePollutionTypes;

  /// When null, no geographic restriction (whole country).
  final String? geoAreaId;
  final bool includeArchived;

  /// Hash of filter dimensions that affect visible sites — use to reset cluster
  /// expansion when filters change mid-animation.
  static int expansionResetKey(MapFilterState s) {
    final List<String> statuses = s.activeStatuses.toList()..sort();
    final List<String> types = s.activePollutionTypes.toList()..sort();
    return Object.hash(
      Object.hashAll(statuses),
      Object.hashAll(types),
      s.geoAreaId,
      s.includeArchived,
    );
  }

  MapFilterState copyWith({
    Set<String>? activeStatuses,
    Set<String>? activePollutionTypes,
    String? geoAreaId,
    bool clearGeoArea = false,
    bool? includeArchived,
  }) {
    return MapFilterState(
      activeStatuses: activeStatuses ?? this.activeStatuses,
      activePollutionTypes: activePollutionTypes ?? this.activePollutionTypes,
      geoAreaId: clearGeoArea ? null : (geoAreaId ?? this.geoAreaId),
      includeArchived: includeArchived ?? this.includeArchived,
    );
  }
}

final mapFilterNotifierProvider =
    NotifierProvider.autoDispose<MapFilterNotifier, MapFilterState>(
      MapFilterNotifier.new,
    );

class MapFilterNotifier extends AutoDisposeNotifier<MapFilterState> {
  static const Set<String> _defaultStatuses = <String>{...mapFilterStatusOrder};
  static int get defaultStatusCount => _defaultStatuses.length;

  @override
  MapFilterState build() {
    return MapFilterState(
      activeStatuses: Set<String>.from(_defaultStatuses),
      activePollutionTypes: reportPollutionTypeCodes.toSet(),
      geoAreaId: null,
      includeArchived: false,
    );
  }

  void setGeoAreaId(String? id) {
    state = state.copyWith(
      geoAreaId: id,
      clearGeoArea: id == null || id.isEmpty,
    );
  }

  void toggleStatus(String status) {
    final String statusCode = mapStatusCodeFromUnknown(status);
    if (state.activeStatuses.contains(statusCode)) {
      if (state.activeStatuses.length == 1) {
        return;
      }
      state = state.copyWith(
        activeStatuses: Set<String>.from(state.activeStatuses)
          ..remove(statusCode),
      );
    } else {
      state = state.copyWith(
        activeStatuses: Set<String>.from(state.activeStatuses)..add(statusCode),
      );
    }
  }

  void togglePollutionType(String type) {
    final String typeCode = reportPollutionTypeCodeFromUnknown(type);
    if (state.activePollutionTypes.contains(typeCode)) {
      if (state.activePollutionTypes.length == 1) {
        return;
      }
      state = state.copyWith(
        activePollutionTypes: Set<String>.from(state.activePollutionTypes)
          ..remove(typeCode),
      );
    } else {
      state = state.copyWith(
        activePollutionTypes: Set<String>.from(state.activePollutionTypes)
          ..add(typeCode),
      );
    }
  }

  void setIncludeArchived({required bool value}) {
    state = state.copyWith(includeArchived: value);
  }

  // ignore: use_setters_to_change_properties, tested full-state replace
  void applyFilters(MapFilterState next) {
    state = next;
  }

  void resetAllFilters() {
    state = MapFilterState(
      activeStatuses: Set<String>.from(_defaultStatuses),
      activePollutionTypes: reportPollutionTypeCodes.toSet(),
      geoAreaId: null,
      includeArchived: false,
    );
  }

  void resetFiltersToCurrentSites(List<PollutionSite> allSites) {
    if (allSites.isEmpty) {
      resetAllFilters();
      return;
    }
    state = MapFilterState(
      activeStatuses: allSites
          .map(
            (PollutionSite s) =>
                mapStatusCodeFromUnknown(s.statusCode ?? s.statusLabel),
          )
          .toSet(),
      activePollutionTypes: reportPollutionTypeCodes.toSet(),
      geoAreaId: null,
      includeArchived: false,
    );
  }
}
