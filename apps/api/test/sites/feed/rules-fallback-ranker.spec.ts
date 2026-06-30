import { RulesFallbackRanker } from '../../../src/sites/feed/ranker/rules-fallback-ranker';

describe('RulesFallbackRanker', () => {
  it('returns one score per feature row', async () => {
    const ranker = new RulesFallbackRanker();
    const scores = await ranker.score([
      {
        version: 'v1',
        siteId: 'site_1',
        engagementVelocity24h: 0.2,
        engagementIntensity: 3,
        freshnessHours: 4,
        distanceKm: 1,
        statusTrust: 1,
        severityIndex: 0.4,
        discussionRatio: 0.3,
        intentRatio: 0.5,
        reportCount: 2,
        wasSeenRecently: 0,
        followsReporter: 1,
      },
    ]);
    expect(scores).toHaveLength(1);
    expect(scores[0]).toBeGreaterThan(0);
  });
});
