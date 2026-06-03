import 'package:feature_home/src/domain/models/comment.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/utils/feed_visible_sites.dart';
import 'package:feature_home/src/presentation/widgets/feed_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PollutionSite _dummy({
  required String id,
  String? urgencyLabel,
  String statusLabel = 'Reported',
  bool isSavedByMe = false,
  double distanceKm = 0,
  double? rankingScore,
  int score = 0,
}) {
  return PollutionSite(
    id: id,
    title: 't',
    description: '',
    statusLabel: statusLabel,
    statusColor: Colors.grey,
    distanceKm: distanceKm,
    score: score,
    participantCount: 0,
    mediaUrls: const <String>['assets/images/content/people_cleaning.png'],
    urgencyLabel: urgencyLabel,
    isSavedByMe: isSavedByMe,
    rankingScore: rankingScore,
  );
}

void main() {
  test('computeVisibleSitesForFilter all returns copy', () {
    final List<PollutionSite> sites = <PollutionSite>[_dummy(id: '1')];
    final List<PollutionSite> out = computeVisibleSitesForFilter(
      source: sites,
      filter: FeedFilter.all,
    );
    expect(out, hasLength(1));
    expect(identical(out, sites), isFalse);
  });

  test('computeVisibleSitesForFilter all and recent preserve server order', () {
    final List<PollutionSite> sites = <PollutionSite>[
      _dummy(id: 'far', distanceKm: 120, rankingScore: 10, score: 1),
      _dummy(id: 'near', distanceKm: 2, rankingScore: 500, score: 50),
    ];
    final List<PollutionSite> allOut = computeVisibleSitesForFilter(
      source: sites,
      filter: FeedFilter.all,
      userLatitude: 41.6,
      userLongitude: 21.7,
    );
    final List<PollutionSite> recentOut = computeVisibleSitesForFilter(
      source: sites,
      filter: FeedFilter.recent,
      userLatitude: 41.6,
      userLongitude: 21.7,
    );
    expect(allOut.map((PollutionSite s) => s.id).toList(), <String>[
      'far',
      'near',
    ]);
    expect(recentOut.map((PollutionSite s) => s.id).toList(), <String>[
      'far',
      'near',
    ]);
  });

  test('feedStatusPriority reported beats cleaned', () {
    expect(
      feedStatusPriority('Reported') > feedStatusPriority('Cleaned'),
      isTrue,
    );
  });

  test('computeVisibleSitesForFilter urgent prefers urgencyLabel sites', () {
    final List<PollutionSite> sites = <PollutionSite>[
      _dummy(id: '1', urgencyLabel: 'needs_attention'),
      _dummy(id: '2'),
    ];
    final List<PollutionSite> out = computeVisibleSitesForFilter(
      source: sites,
      filter: FeedFilter.urgent,
    );
    expect(out.map((PollutionSite s) => s.id).toList(), <String>['1']);
  });

  test(
    'computeVisibleSitesForFilter saved returns full list when all saved',
    () {
      final List<PollutionSite> sites = <PollutionSite>[
        _dummy(id: '1', isSavedByMe: true),
        _dummy(id: '2', isSavedByMe: true),
      ];
      final List<PollutionSite> out = computeVisibleSitesForFilter(
        source: sites,
        filter: FeedFilter.saved,
      );
      expect(out, hasLength(2));
    },
  );

  test('computeVisibleSitesForFilter saved keeps only isSavedByMe sites', () {
    final List<PollutionSite> sites = <PollutionSite>[
      _dummy(id: '1', isSavedByMe: true),
      _dummy(id: '2', isSavedByMe: false),
      _dummy(id: '3', isSavedByMe: true),
    ];
    final List<PollutionSite> out = computeVisibleSitesForFilter(
      source: sites,
      filter: FeedFilter.saved,
    );
    expect(out.map((PollutionSite s) => s.id).toList(), <String>['1', '3']);
  });

  test(
    'computeVisibleSitesForFilter saved trusts server list when flags missing',
    () {
      final List<PollutionSite> sites = <PollutionSite>[
        _dummy(id: 'saved-a', isSavedByMe: false),
        _dummy(id: 'saved-b', isSavedByMe: false),
      ];
      final List<PollutionSite> out = computeVisibleSitesForFilter(
        source: sites,
        filter: FeedFilter.saved,
      );
      expect(out.map((PollutionSite s) => s.id).toList(), <String>[
        'saved-a',
        'saved-b',
      ]);
    },
  );

  test('patchPollutionSitesSavedFlag updates matching id only', () {
    final List<PollutionSite> sites = <PollutionSite>[
      _dummy(id: '1', isSavedByMe: false),
      _dummy(id: '2', isSavedByMe: false),
    ];
    final List<PollutionSite> out = patchPollutionSitesSavedFlag(
      sites,
      '1',
      true,
    );
    expect(out[0].isSavedByMe, isTrue);
    expect(out[1].isSavedByMe, isFalse);
    expect(identical(out, sites), isFalse);
  });

  test('patchPollutionSitesSavedFlag empty siteId returns copy of source', () {
    final List<PollutionSite> sites = <PollutionSite>[_dummy(id: '1')];
    final List<PollutionSite> out = patchPollutionSitesSavedFlag(
      sites,
      '',
      true,
    );
    expect(out, hasLength(1));
    expect(out[0].isSavedByMe, isFalse);
  });

  test(
    'patchPollutionSitesCommentsCount sets count and clears embedded comments',
    () {
      final DateTime t = DateTime.utc(2026, 1, 1);
      final PollutionSite withPreview = _dummy(id: '1').copyWith(
        commentsCount: 3,
        comments: <Comment>[
          Comment(id: 'c1', authorName: 'A', text: 'x', createdAt: t),
        ],
      );
      final List<PollutionSite> out = patchPollutionSitesCommentsCount(
        <PollutionSite>[withPreview],
        '1',
        1,
      );
      expect(out[0].commentsCount, 1);
      expect(out[0].comments, isEmpty);
      expect(withPreview.commentsCount, 3);
    },
  );

  test('nearby filter uses user location when server distance is unknown', () {
    final List<PollutionSite> out = computeVisibleSitesForFilter(
      source: <PollutionSite>[
        _dummy(
          id: 'near',
        ).copyWith(distanceKm: -1, latitude: 41.9981, longitude: 21.4254),
        _dummy(
          id: 'far',
        ).copyWith(distanceKm: -1, latitude: 41.85, longitude: 22),
      ],
      filter: FeedFilter.nearby,
      userLatitude: 41.9973,
      userLongitude: 21.4280,
    );
    expect(out.first.id, 'near');
  });
}
