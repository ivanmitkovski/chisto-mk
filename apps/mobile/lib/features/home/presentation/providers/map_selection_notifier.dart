import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/providers/repository_providers.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_sites_notifier.dart';

class MapSelectionState {
  const MapSelectionState({this.selected, this.pendingFocusBusy = false});

  final PollutionSite? selected;
  final bool pendingFocusBusy;

  MapSelectionState copyWith({
    PollutionSite? selected,
    bool clearSelected = false,
    bool? pendingFocusBusy,
  }) {
    return MapSelectionState(
      selected: clearSelected ? null : (selected ?? this.selected),
      pendingFocusBusy: pendingFocusBusy ?? this.pendingFocusBusy,
    );
  }
}

final mapSelectionNotifierProvider =
    NotifierProvider<MapSelectionNotifier, MapSelectionState>(
  MapSelectionNotifier.new,
);

class MapSelectionNotifier extends Notifier<MapSelectionState> {
  @override
  MapSelectionState build() => const MapSelectionState();

  void select(PollutionSite site) {
    state = state.copyWith(selected: site);
  }

  void deselect() {
    state = state.copyWith(clearSelected: true);
  }

  /// Resolves [siteId] from in-memory list or [getSiteById]; returns coordinates when found.
  Future<({PollutionSite site, LatLng point})?> resolveSiteAndPoint(
    String siteId,
  ) async {
    final PollutionSite? fetched =
        await ref.read(sitesRepositoryProvider).getSiteById(siteId);
    if (fetched != null &&
        fetched.latitude != null &&
        fetched.longitude != null) {
      return (
        site: fetched,
        point: LatLng(fetched.latitude!, fetched.longitude!),
      );
    }
    return null;
  }

  Future<void> runPendingFocus({
    required String siteId,
    required void Function(PollutionSite site, LatLng point) onLocated,
    required void Function() onUnavailable,
    required void Function() onError,
  }) async {
    if (state.pendingFocusBusy) {
      return;
    }
    state = state.copyWith(pendingFocusBusy: true);
    try {
      final ({PollutionSite site, LatLng point})? resolved =
          await resolveSiteAndPoint(siteId);
      if (resolved == null) {
        onUnavailable();
        return;
      }
      ref.read(mapSitesNotifierProvider.notifier).upsertSiteFromFocus(resolved.site);
      onLocated(resolved.site, resolved.point);
    } on Exception catch (_) {
      onError();
    } finally {
      state = state.copyWith(pendingFocusBusy: false);
    }
  }
}
