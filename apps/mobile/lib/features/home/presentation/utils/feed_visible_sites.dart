import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_filter_sheet.dart';

/// Updates [isSavedByMe] for [siteId] in a feed list (keeps client-side [FeedFilter.saved] in sync).
List<PollutionSite> patchPollutionSitesSavedFlag(
  List<PollutionSite> source,
  String siteId,
  bool isSavedByMe,
) {
  if (siteId.isEmpty) {
    return List<PollutionSite>.from(source);
  }
  return source
      .map(
        (PollutionSite s) =>
            s.id == siteId ? s.copyWith(isSavedByMe: isSavedByMe) : s,
      )
      .toList(growable: false);
}

int feedStatusPriority(String statusLabel) {
  final String normalized = statusLabel.toLowerCase();
  if (normalized.contains('reported')) {
    return 4;
  }
  if (normalized.contains('verified')) {
    return 3;
  }
  if (normalized.contains('in progress')) {
    return 2;
  }
  if (normalized.contains('cleanup')) {
    return 1;
  }
  return 0;
}

List<PollutionSite> computeVisibleSitesForFilter({
  required List<PollutionSite> source,
  required FeedFilter filter,
  String feedVariant = 'v1',
}) {
  final bool trustServerOrder = feedVariant == 'v2' || feedVariant == 'v2-shadow';
  switch (filter) {
    case FeedFilter.all:
      return List<PollutionSite>.from(source);
    case FeedFilter.urgent:
      final List<PollutionSite> urgent =
          source.where((PollutionSite s) => s.urgencyLabel != null).toList();
      if (urgent.isNotEmpty) {
        return urgent;
      }
      final List<PollutionSite> fallback = List<PollutionSite>.from(source)
        ..sort((PollutionSite a, PollutionSite b) {
          final int scoreA = feedStatusPriority(a.statusLabel);
          final int scoreB = feedStatusPriority(b.statusLabel);
          if (scoreA != scoreB) {
            return scoreB.compareTo(scoreA);
          }
          return b.commentsCount.compareTo(a.commentsCount);
        });
      return fallback;
    case FeedFilter.nearby:
      return List<PollutionSite>.from(source)
        ..sort((PollutionSite a, PollutionSite b) {
          final bool aKnown = a.distanceKm >= 0;
          final bool bKnown = b.distanceKm >= 0;
          if (aKnown != bKnown) {
            return aKnown ? -1 : 1;
          }
          if (!aKnown && !bKnown) {
            return b.score.compareTo(a.score);
          }
          return a.distanceKm.compareTo(b.distanceKm);
        });
    case FeedFilter.mostVoted:
      if (trustServerOrder) {
        return List<PollutionSite>.from(source);
      }
      return List<PollutionSite>.from(source)
        ..sort((PollutionSite a, PollutionSite b) {
          final int supportA =
              a.score + (a.commentsCount * 3) + (a.shareCount * 4);
          final int supportB =
              b.score + (b.commentsCount * 3) + (b.shareCount * 4);
          return supportB.compareTo(supportA);
        });
    case FeedFilter.recent:
      if (trustServerOrder) {
        return List<PollutionSite>.from(source);
      }
      return List<PollutionSite>.from(source)
        ..sort(
          (PollutionSite a, PollutionSite b) =>
              (b.rankingScore ?? 0).compareTo(a.rankingScore ?? 0),
        );
    case FeedFilter.saved:
      return source
          .where((PollutionSite s) => s.isSavedByMe)
          .toList(growable: false);
  }
}
