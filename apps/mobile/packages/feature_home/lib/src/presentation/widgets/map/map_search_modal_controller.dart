import 'dart:async';

import 'package:feature_home/src/data/map_search_recents_store.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/domain/repositories/sites_repository_types.dart';
import 'package:feature_home/src/presentation/providers/map_search_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Search query, recents, and result selection logic for [MapSearchModal].
class MapSearchModalController {
  MapSearchModalController({required this.onRecentsChanged});

  final void Function(List<String> recents) onRecentsChanged;

  List<String> recents = const <String>[];

  Future<void> refreshRecents() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    recents = MapSearchRecentsStore.readSync(prefs);
    onRecentsChanged(recents);
  }

  Future<void> persistRecentQuery(String query) async {
    final String trimmed = query.trim();
    if (trimmed.length < MapSearchState.minRemoteQueryLength) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await MapSearchRecentsStore.add(prefs, trimmed);
    await refreshRecents();
  }

  Future<void> clearRecents() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await MapSearchRecentsStore.clear(prefs);
    await refreshRecents();
  }

  PollutionSite? firstSearchResult(MapSearchState state) {
    if (state.localResults.isNotEmpty) {
      return state.localResults.first;
    }
    if (state.remoteOnlyResults.isNotEmpty) {
      return state.remoteOnlyResults.first;
    }
    return null;
  }

  List<PollutionSite> previewSites(
    List<PollutionSite> pool, {
    required int limit,
  }) {
    final List<PollutionSite> sorted = List<PollutionSite>.from(pool);
    sorted.sort((PollutionSite a, PollutionSite b) {
      final bool aHasDistance = a.distanceKm >= 0;
      final bool bHasDistance = b.distanceKm >= 0;
      if (aHasDistance && bHasDistance) {
        return a.distanceKm.compareTo(b.distanceKm);
      }
      if (aHasDistance) {
        return -1;
      }
      if (bHasDistance) {
        return 1;
      }
      return a.title.compareTo(b.title);
    });
    if (sorted.length <= limit) {
      return sorted;
    }
    return sorted.sublist(0, limit);
  }

  Future<void> onGeoIntentTap({
    required SiteMapSearchGeoIntent intent,
    required String queryText,
    required void Function(SiteMapSearchGeoIntent intent) onSelected,
  }) async {
    final String trimmed = queryText.trim();
    final String recent = trimmed.length >= MapSearchState.minRemoteQueryLength
        ? trimmed
        : intent.label.trim();
    await persistRecentQuery(recent);
    onSelected(intent);
  }
}
