import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/utils/feed_visible_sites.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PollutionSite _dummy({
  required String id,
  String? urgencyLabel,
  String statusLabel = 'Reported',
  bool isSavedByMe = false,
}) {
  return PollutionSite(
    id: id,
    title: 't',
    description: '',
    statusLabel: statusLabel,
    statusColor: Colors.grey,
    distanceKm: 0,
    score: 0,
    participantCount: 0,
    mediaUrls: const <String>['assets/images/content/people_cleaning.png'],
    urgencyLabel: urgencyLabel,
    isSavedByMe: isSavedByMe,
  );
}

void main() {
  test('computeVisibleSitesForFilter all returns copy', () {
    final List<PollutionSite> sites = <PollutionSite>[_dummy(id: '1')];
    final List<PollutionSite> out =
        computeVisibleSitesForFilter(source: sites, filter: FeedFilter.all);
    expect(out, hasLength(1));
    expect(identical(out, sites), isFalse);
  });

  test('feedStatusPriority reported beats cleaned', () {
    expect(feedStatusPriority('Reported') > feedStatusPriority('Cleaned'), isTrue);
  });

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

  test('patchPollutionSitesSavedFlag updates matching id only', () {
    final List<PollutionSite> sites = <PollutionSite>[
      _dummy(id: '1', isSavedByMe: false),
      _dummy(id: '2', isSavedByMe: false),
    ];
    final List<PollutionSite> out =
        patchPollutionSitesSavedFlag(sites, '1', true);
    expect(out[0].isSavedByMe, isTrue);
    expect(out[1].isSavedByMe, isFalse);
    expect(identical(out, sites), isFalse);
  });

  test('patchPollutionSitesSavedFlag empty siteId returns copy of source', () {
    final List<PollutionSite> sites = <PollutionSite>[_dummy(id: '1')];
    final List<PollutionSite> out = patchPollutionSitesSavedFlag(sites, '', true);
    expect(out, hasLength(1));
    expect(out[0].isSavedByMe, isFalse);
  });
}
