import { FeedRankingService } from '../../src/sites/feed-ranking.service';

describe('FeedRankingService', () => {
  const service = new FeedRankingService();
  const now = new Date('2026-03-27T10:00:00.000Z');
  const base = {
    status: 'VERIFIED',
    distanceKm: 2,
    radiusKm: 10,
    reportCount: 1,
  };

  it('prefers fresher content when engagement is equal', () => {
    const fresh = service.score(
      {
        siteId: 'site_fresh',
        createdAt: new Date('2026-03-27T09:30:00.000Z'),
        upvotesCount: 5,
        commentsCount: 2,
        savesCount: 1,
        sharesCount: 1,
        ...base,
      },
      now,
    );
    const old = service.score(
      {
        siteId: 'site_old',
        createdAt: new Date('2026-03-25T09:30:00.000Z'),
        upvotesCount: 5,
        commentsCount: 2,
        savesCount: 1,
        sharesCount: 1,
        ...base,
      },
      now,
    );

    expect(fresh).toBeGreaterThan(old);
  });

  it('boosts higher engagement for similarly aged content', () => {
    const low = service.score(
      {
        siteId: 'site_low',
        createdAt: new Date('2026-03-27T08:00:00.000Z'),
        upvotesCount: 1,
        commentsCount: 0,
        savesCount: 0,
        sharesCount: 0,
        ...base,
      },
      now,
    );
    const high = service.score(
      {
        siteId: 'site_high',
        createdAt: new Date('2026-03-27T08:00:00.000Z'),
        upvotesCount: 22,
        commentsCount: 9,
        savesCount: 5,
        sharesCount: 4,
        ...base,
      },
      now,
    );

    expect(high).toBeGreaterThan(low);
  });

  it('is deterministic for same site and hour bucket', () => {
    const a = service.score(
      {
        siteId: 'site_same',
        createdAt: new Date('2026-03-27T08:00:00.000Z'),
        upvotesCount: 6,
        commentsCount: 3,
        savesCount: 1,
        sharesCount: 2,
        ...base,
      },
      now,
    );
    const b = service.score(
      {
        siteId: 'site_same',
        createdAt: new Date('2026-03-27T08:00:00.000Z'),
        upvotesCount: 6,
        commentsCount: 3,
        savesCount: 1,
        sharesCount: 2,
        ...base,
      },
      now,
    );

    expect(a).toBe(b);
  });

  it('returns explainability reason codes for ranked item', () => {
    const detailed = service.scoreDetailed(
      {
        siteId: 'site_reason',
        createdAt: new Date('2026-03-27T09:45:00.000Z'),
        upvotesCount: 6,
        commentsCount: 3,
        savesCount: 1,
        sharesCount: 1,
        status: 'VERIFIED',
        distanceKm: 1.5,
        radiusKm: 10,
        reportCount: 2,
      },
      now,
    );
    expect(detailed.reasonCodes.length).toBeGreaterThan(0);
    expect(detailed.components.recency).toBeGreaterThan(0);
    expect(detailed.score).toBeGreaterThan(0);
  });

  it('uses distance signal only when geo context exists', () => {
    const nearWithGeo = service.score(
      {
        siteId: 'site_near_geo',
        createdAt: new Date('2026-03-27T08:00:00.000Z'),
        upvotesCount: 4,
        commentsCount: 2,
        savesCount: 1,
        sharesCount: 1,
        status: 'VERIFIED',
        distanceKm: 1,
        radiusKm: 10,
        reportCount: 2,
      },
      now,
    );
    const farWithGeo = service.score(
      {
        siteId: 'site_far_geo',
        createdAt: new Date('2026-03-27T08:00:00.000Z'),
        upvotesCount: 4,
        commentsCount: 2,
        savesCount: 1,
        sharesCount: 1,
        status: 'VERIFIED',
        distanceKm: 9,
        radiusKm: 10,
        reportCount: 2,
      },
      now,
    );
    const nearWithoutGeo = service.score(
      {
        siteId: 'site_near_nogeo',
        createdAt: new Date('2026-03-27T08:00:00.000Z'),
        upvotesCount: 4,
        commentsCount: 2,
        savesCount: 1,
        sharesCount: 1,
        status: 'VERIFIED',
        reportCount: 2,
      },
      now,
    );
    const farWithoutGeo = service.score(
      {
        siteId: 'site_far_nogeo',
        createdAt: new Date('2026-03-27T08:00:00.000Z'),
        upvotesCount: 4,
        commentsCount: 2,
        savesCount: 1,
        sharesCount: 1,
        status: 'VERIFIED',
        reportCount: 2,
      },
      now,
    );

    expect(nearWithGeo).toBeGreaterThan(farWithGeo);
    expect(Math.abs(nearWithoutGeo - farWithoutGeo)).toBeLessThan(0.05);
  });

  it('applies anti-spam saturation for bursty low-quality engagement', () => {
    const spammy = service.score(
      {
        siteId: 'site_spammy',
        createdAt: new Date('2026-03-27T09:00:00.000Z'),
        upvotesCount: 120,
        commentsCount: 0,
        savesCount: 0,
        sharesCount: 0,
        status: 'REPORTED',
        distanceKm: 3,
        radiusKm: 10,
        reportCount: 1,
      },
      now,
    );
    const healthy = service.score(
      {
        siteId: 'site_healthy',
        createdAt: new Date('2026-03-27T09:00:00.000Z'),
        upvotesCount: 45,
        commentsCount: 10,
        savesCount: 6,
        sharesCount: 3,
        status: 'REPORTED',
        distanceKm: 3,
        radiusKm: 10,
        reportCount: 1,
      },
      now,
    );
    expect(healthy).toBeGreaterThan(spammy);
  });

  it('adds medium exploration boost for underexposed promising content', () => {
    const underExposedWithQuality = service.score(
      {
        siteId: 'site_under_exposed_quality',
        createdAt: new Date('2026-03-27T09:10:00.000Z'),
        upvotesCount: 3,
        commentsCount: 2,
        savesCount: 1,
        sharesCount: 0,
        status: 'REPORTED',
        distanceKm: 2,
        radiusKm: 10,
        reportCount: 2,
      },
      now,
    );
    const underExposedNoQuality = service.score(
      {
        siteId: 'site_under_exposed_no_quality',
        createdAt: new Date('2026-03-27T09:10:00.000Z'),
        upvotesCount: 3,
        commentsCount: 0,
        savesCount: 0,
        sharesCount: 0,
        status: 'REPORTED',
        distanceKm: 2,
        radiusKm: 10,
        reportCount: 2,
      },
      now,
    );
    expect(underExposedWithQuality).toBeGreaterThan(underExposedNoQuality);
    expect(underExposedWithQuality).toBeGreaterThan(0);
  });
});
