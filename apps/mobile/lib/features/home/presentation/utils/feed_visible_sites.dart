import 'dart:math' as math;

import 'package:chisto_mobile/features/home/domain/models/comment.dart';
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

/// Updates [commentsCount] for [siteId] and clears embedded [PollutionSite.comments] so
/// [PollutionSite.commentCount] cannot stay inflated from a stale preview tree after edits
/// in the comments sheet.
List<PollutionSite> patchPollutionSitesCommentsCount(
  List<PollutionSite> source,
  String siteId,
  int commentsCount,
) {
  if (siteId.isEmpty) {
    return List<PollutionSite>.from(source);
  }
  return source
      .map(
        (PollutionSite s) => s.id == siteId
            ? s.copyWith(
                commentsCount: commentsCount,
                comments: const <Comment>[],
              )
            : s,
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
  double? userLatitude,
  double? userLongitude,
}) {
  final bool hasUserLocation = userLatitude != null && userLongitude != null;
  final bool trustServerOrder = feedVariant == 'v2' || feedVariant == 'v2-shadow';
  switch (filter) {
    case FeedFilter.all:
      final List<PollutionSite> all = List<PollutionSite>.from(source);
      if (hasUserLocation && !trustServerOrder) {
        final double lat = userLatitude;
        final double lng = userLongitude;
        all.sort(
          (PollutionSite a, PollutionSite b) => _hybridRelevanceScore(
            b,
            userLatitude: lat,
            userLongitude: lng,
          ).compareTo(
            _hybridRelevanceScore(
              a,
              userLatitude: lat,
              userLongitude: lng,
            ),
          ),
        );
      }
      return all;
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
          final double? aDistance = _effectiveDistanceKm(
            a,
            userLatitude: userLatitude,
            userLongitude: userLongitude,
          );
          final double? bDistance = _effectiveDistanceKm(
            b,
            userLatitude: userLatitude,
            userLongitude: userLongitude,
          );
          final bool aKnown = aDistance != null;
          final bool bKnown = bDistance != null;
          if (aKnown != bKnown) {
            return aKnown ? -1 : 1;
          }
          if (!aKnown && !bKnown) {
            return _supportScore(b).compareTo(_supportScore(a));
          }
          final int dist = aDistance!.compareTo(bDistance!);
          if (dist != 0) {
            return dist;
          }
          return _supportScore(b).compareTo(_supportScore(a));
        });
    case FeedFilter.mostVoted:
      if (trustServerOrder) {
        return List<PollutionSite>.from(source);
      }
      return List<PollutionSite>.from(source)
        ..sort((PollutionSite a, PollutionSite b) {
          final int supportA = _supportScore(a);
          final int supportB = _supportScore(b);
          if (supportA != supportB) {
            return supportB.compareTo(supportA);
          }
          final double? aDistance = _effectiveDistanceKm(
            a,
            userLatitude: userLatitude,
            userLongitude: userLongitude,
          );
          final double? bDistance = _effectiveDistanceKm(
            b,
            userLatitude: userLatitude,
            userLongitude: userLongitude,
          );
          if (aDistance != null && bDistance != null) {
            return aDistance.compareTo(bDistance);
          }
          if (aDistance != null) {
            return -1;
          }
          if (bDistance != null) {
            return 1;
          }
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

int _supportScore(PollutionSite site) =>
    site.score + (site.commentsCount * 3) + (site.shareCount * 4);

double _hybridRelevanceScore(
  PollutionSite site, {
  required double userLatitude,
  required double userLongitude,
}) {
  final double recencyBoost = (site.rankingScore ?? 0).clamp(0, 500);
  final double socialBoost = _supportScore(site).toDouble();
  final double distancePenalty = (_effectiveDistanceKm(
            site,
            userLatitude: userLatitude,
            userLongitude: userLongitude,
          ) ??
          80) *
      4.2;
  return recencyBoost + socialBoost - distancePenalty;
}

double? _effectiveDistanceKm(
  PollutionSite site, {
  double? userLatitude,
  double? userLongitude,
}) {
  if (site.distanceKm >= 0) {
    return site.distanceKm;
  }
  if (userLatitude == null ||
      userLongitude == null ||
      site.latitude == null ||
      site.longitude == null) {
    return null;
  }
  return _haversineKm(
    userLatitude,
    userLongitude,
    site.latitude!,
    site.longitude!,
  );
}

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const double earthKm = 6371.0;
  final double dLat = _degToRad(lat2 - lat1);
  final double dLon = _degToRad(lon2 - lon1);
  final double a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degToRad(lat1)) *
          math.cos(_degToRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthKm * c;
}

double _degToRad(double deg) => deg * (math.pi / 180.0);
