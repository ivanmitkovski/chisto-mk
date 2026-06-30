import 'dart:async';

import 'package:feature_home/src/domain/repositories/sites_repository.dart';
import 'package:feature_home/src/presentation/providers/repository_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class SiteCoReportersState {
  const SiteCoReportersState({
    required this.items,
    required this.total,
    required this.nextPage,
    required this.hasMore,
    required this.initialLoading,
    required this.loadingMore,
    this.error,
  });

  final List<SiteCoReporterItem> items;
  final int total;
  final int nextPage;
  final bool hasMore;
  final bool initialLoading;
  final bool loadingMore;
  final Object? error;
}

final siteCoReportersNotifierProvider = NotifierProvider.autoDispose
    .family<SiteCoReportersNotifier, SiteCoReportersState, String>(
      SiteCoReportersNotifier.new,
    );

class SiteCoReportersNotifier
    extends AutoDisposeFamilyNotifier<SiteCoReportersState, String> {
  static const int _pageSize = 50;

  String get _siteId => arg;

  SitesRepository get _repo => ref.read(sitesRepositoryProvider);

  @override
  SiteCoReportersState build(String siteId) {
    unawaited(loadInitial());
    return const SiteCoReportersState(
      items: <SiteCoReporterItem>[],
      total: 0,
      nextPage: 1,
      hasMore: true,
      initialLoading: true,
      loadingMore: false,
    );
  }

  Future<void> loadInitial() async {
    state = const SiteCoReportersState(
      items: <SiteCoReporterItem>[],
      total: 0,
      nextPage: 1,
      hasMore: true,
      initialLoading: true,
      loadingMore: false,
    );
    try {
      final SiteCoReportersResult result = await _repo.getSiteCoReporters(
        _siteId,
        page: 1,
        limit: _pageSize,
      );
      state = SiteCoReportersState(
        items: List<SiteCoReporterItem>.from(result.items),
        total: result.total,
        nextPage: result.hasMore ? result.page + 1 : result.page,
        hasMore: result.hasMore,
        initialLoading: false,
        loadingMore: false,
      );
    } catch (e) {
      state = SiteCoReportersState(
        items: state.items,
        total: state.total,
        nextPage: state.nextPage,
        hasMore: state.hasMore,
        initialLoading: false,
        loadingMore: false,
        error: e,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.initialLoading || state.loadingMore || !state.hasMore) {
      return;
    }
    state = SiteCoReportersState(
      items: state.items,
      total: state.total,
      nextPage: state.nextPage,
      hasMore: state.hasMore,
      initialLoading: false,
      loadingMore: true,
    );
    try {
      final SiteCoReportersResult result = await _repo.getSiteCoReporters(
        _siteId,
        page: state.nextPage,
        limit: _pageSize,
      );
      final Set<String> seen = <String>{
        for (final SiteCoReporterItem i in state.items) i.id,
      };
      final List<SiteCoReporterItem> merged = List<SiteCoReporterItem>.from(
        state.items,
      );
      for (final SiteCoReporterItem item in result.items) {
        if (seen.add(item.id)) {
          merged.add(item);
        }
      }
      state = SiteCoReportersState(
        items: merged,
        total: result.total,
        nextPage: result.hasMore ? result.page + 1 : result.page,
        hasMore: result.hasMore,
        initialLoading: false,
        loadingMore: false,
      );
    } catch (e) {
      state = SiteCoReportersState(
        items: state.items,
        total: state.total,
        nextPage: state.nextPage,
        hasMore: state.hasMore,
        initialLoading: false,
        loadingMore: false,
        error: e,
      );
    }
  }
}
