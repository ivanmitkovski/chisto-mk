import 'dart:async';

import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:feature_home/src/domain/models/comment.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/domain/repositories/sites_repository.dart';
import 'package:feature_home/src/presentation/providers/repository_providers.dart';
import 'package:feature_home/src/presentation/utils/site_comment_mapping.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SiteCommentsRouteIssue { none, siteNotFound, bootstrapFailed }

enum SiteCommentsLoadMoreResult { success, skipped, failed }

@immutable
class SiteCommentsRouteState {
  const SiteCommentsRouteState({
    required this.loading,
    required this.issue,
    this.site,
    this.comments = const <Comment>[],
    this.commentsPage = 1,
    this.hasMoreComments = false,
    this.loadingMoreComments = false,
    this.activeSort = 'top',
  });

  factory SiteCommentsRouteState.initial() => const SiteCommentsRouteState(
    loading: true,
    issue: SiteCommentsRouteIssue.none,
  );

  final bool loading;
  final SiteCommentsRouteIssue issue;
  final PollutionSite? site;
  final List<Comment> comments;
  final int commentsPage;
  final bool hasMoreComments;
  final bool loadingMoreComments;
  final String activeSort;

  SiteCommentsRouteState copyWith({
    bool? loading,
    SiteCommentsRouteIssue? issue,
    PollutionSite? site,
    List<Comment>? comments,
    int? commentsPage,
    bool? hasMoreComments,
    bool? loadingMoreComments,
    String? activeSort,
  }) {
    return SiteCommentsRouteState(
      loading: loading ?? this.loading,
      issue: issue ?? this.issue,
      site: site ?? this.site,
      comments: comments ?? this.comments,
      commentsPage: commentsPage ?? this.commentsPage,
      hasMoreComments: hasMoreComments ?? this.hasMoreComments,
      loadingMoreComments: loadingMoreComments ?? this.loadingMoreComments,
      activeSort: activeSort ?? this.activeSort,
    );
  }
}

final siteCommentsRouteNotifierProvider = NotifierProvider.autoDispose
    .family<SiteCommentsRouteNotifier, SiteCommentsRouteState, String>(
      SiteCommentsRouteNotifier.new,
    );

class SiteCommentsRouteNotifier
    extends AutoDisposeFamilyNotifier<SiteCommentsRouteState, String> {
  static const int _pageSize = 20;

  String get _siteId => arg;

  SitesRepository get _repo => ref.read(sitesRepositoryProvider);

  @override
  SiteCommentsRouteState build(String siteId) {
    unawaited(_bootstrap());
    return SiteCommentsRouteState.initial();
  }

  bool _hasMoreFromResult(SiteCommentsResult result) {
    return result.items.isNotEmpty &&
        result.items.length >= result.limit &&
        (result.page * result.limit) < result.total;
  }

  Future<void> _bootstrap() async {
    try {
      final PollutionSite? site = await _repo.getSiteById(_siteId);
      if (site == null) {
        state = state.copyWith(
          loading: false,
          issue: SiteCommentsRouteIssue.siteNotFound,
        );
        return;
      }
      final SiteCommentsResult result = await _repo.getSiteComments(
        _siteId,
        page: 1,
        limit: _pageSize,
        sort: 'top',
      );
      state = state.copyWith(
        site: site,
        activeSort: 'top',
        commentsPage: result.page,
        comments: result.items
            .map(
              (SiteCommentItem item) => commentFromSiteCommentItem(
                ref.read(authStateProvider).userId ?? '',
                item,
              ),
            )
            .toList(),
        hasMoreComments: _hasMoreFromResult(result),
        loading: false,
        issue: SiteCommentsRouteIssue.none,
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        issue: SiteCommentsRouteIssue.bootstrapFailed,
      );
    }
  }

  Future<void> retryBootstrap() async {
    state = SiteCommentsRouteState.initial();
    await _bootstrap();
  }

  Future<SiteCommentsLoadMoreResult> loadMoreComments() async {
    if (!state.hasMoreComments || state.loadingMoreComments) {
      return SiteCommentsLoadMoreResult.skipped;
    }
    state = state.copyWith(loadingMoreComments: true);
    try {
      final SiteCommentsResult result = await _repo.getSiteComments(
        _siteId,
        page: state.commentsPage + 1,
        limit: _pageSize,
        sort: state.activeSort,
      );
      final List<Comment> batch = result.items
          .map(
            (SiteCommentItem item) => commentFromSiteCommentItem(
              ref.read(authStateProvider).userId ?? '',
              item,
            ),
          )
          .toList();
      if (batch.isEmpty) {
        state = state.copyWith(
          hasMoreComments: false,
          loadingMoreComments: false,
        );
        return SiteCommentsLoadMoreResult.success;
      }
      final Set<String> existingIds = <String>{
        for (final Comment c in state.comments) c.id,
      };
      final List<Comment> merged = List<Comment>.from(state.comments);
      for (final Comment c in batch) {
        if (!existingIds.contains(c.id)) {
          merged.add(c);
          existingIds.add(c.id);
        }
      }
      if (merged.length == state.comments.length) {
        state = state.copyWith(
          hasMoreComments: false,
          loadingMoreComments: false,
        );
        return SiteCommentsLoadMoreResult.success;
      }
      state = state.copyWith(
        comments: merged,
        commentsPage: result.page,
        hasMoreComments: _hasMoreFromResult(result),
        loadingMoreComments: false,
      );
      return SiteCommentsLoadMoreResult.success;
    } catch (_) {
      state = state.copyWith(loadingMoreComments: false);
      return SiteCommentsLoadMoreResult.failed;
    }
  }

  void replaceComments(List<Comment> next) {
    state = state.copyWith(comments: next);
  }

  /// Pull-to-refresh: reload first page for the active sort (keeps scroll position best-effort).
  Future<void> refreshComments() async {
    final SiteCommentsResult result = await _repo.getSiteComments(
      _siteId,
      page: 1,
      limit: _pageSize,
      sort: state.activeSort,
    );
    state = state.copyWith(
      comments: result.items
          .map(
            (SiteCommentItem item) => commentFromSiteCommentItem(
              ref.read(authStateProvider).userId ?? '',
              item,
            ),
          )
          .toList(),
      commentsPage: result.page,
      hasMoreComments: _hasMoreFromResult(result),
    );
  }
}
