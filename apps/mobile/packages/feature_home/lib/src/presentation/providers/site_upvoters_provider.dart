import 'dart:async';

import 'package:feature_home/src/domain/repositories/sites_repository.dart';
import 'package:feature_home/src/presentation/providers/repository_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class SiteUpvotersState {
  const SiteUpvotersState({
    required this.items,
    required this.total,
    required this.nextPage,
    required this.hasMore,
    required this.initialLoading,
    required this.loadingMore,
    this.error,
  });

  final List<SiteUpvoterItem> items;
  final int total;
  final int nextPage;
  final bool hasMore;
  final bool initialLoading;
  final bool loadingMore;
  final Object? error;
}

final siteUpvotersNotifierProvider = NotifierProvider.autoDispose
    .family<SiteUpvotersNotifier, SiteUpvotersState, String>(
      SiteUpvotersNotifier.new,
    );

class SiteUpvotersNotifier
    extends AutoDisposeFamilyNotifier<SiteUpvotersState, String> {
  static const int _pageSize = 50;

  String get _siteId => arg;

  SitesRepository get _repo => ref.read(sitesRepositoryProvider);

  @override
  SiteUpvotersState build(String siteId) {
    unawaited(loadInitial());
    return const SiteUpvotersState(
      items: <SiteUpvoterItem>[],
      total: 0,
      nextPage: 1,
      hasMore: true,
      initialLoading: true,
      loadingMore: false,
    );
  }

  Future<void> loadInitial() async {
    state = const SiteUpvotersState(
      items: <SiteUpvoterItem>[],
      total: 0,
      nextPage: 1,
      hasMore: true,
      initialLoading: true,
      loadingMore: false,
    );
    try {
      final SiteUpvotesResult result = await _repo.getSiteUpvotes(
        _siteId,
        page: 1,
        limit: _pageSize,
      );
      state = SiteUpvotersState(
        items: List<SiteUpvoterItem>.from(result.items),
        total: result.total,
        nextPage: result.hasMore ? result.page + 1 : result.page,
        hasMore: result.hasMore,
        initialLoading: false,
        loadingMore: false,
      );
    } catch (e) {
      state = SiteUpvotersState(
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
    state = SiteUpvotersState(
      items: state.items,
      total: state.total,
      nextPage: state.nextPage,
      hasMore: state.hasMore,
      initialLoading: false,
      loadingMore: true,
    );
    try {
      final SiteUpvotesResult result = await _repo.getSiteUpvotes(
        _siteId,
        page: state.nextPage,
        limit: _pageSize,
      );
      final Set<String> seen = <String>{
        for (final SiteUpvoterItem i in state.items) i.userId,
      };
      final List<SiteUpvoterItem> merged = List<SiteUpvoterItem>.from(
        state.items,
      );
      for (final SiteUpvoterItem item in result.items) {
        if (seen.add(item.userId)) {
          merged.add(item);
        }
      }
      state = SiteUpvotersState(
        items: merged,
        total: result.total,
        nextPage: result.hasMore ? result.page + 1 : result.page,
        hasMore: result.hasMore,
        initialLoading: false,
        loadingMore: false,
      );
    } catch (e) {
      state = SiteUpvotersState(
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
