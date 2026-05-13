import { BadRequestException } from '@nestjs/common';
import { SitesFeedService } from '../../src/sites/sites-feed.service';

describe('SitesFeedService', () => {
  it('rejects partial geo query (lat without lng)', async () => {
    const feedQuery = { computeFeedList: jest.fn() } as never;
    const feedCache = {
      buildFeedCacheKey: jest.fn(() => 'k'),
      get: jest.fn(() => undefined),
      set: jest.fn(),
      invalidate: jest.fn(),
    } as never;
    const feedPreferences = {
      applyUserPreferences: jest.fn((rows: unknown[]) => rows),
      setVariantMemo: jest.fn(),
      getFeedVariantForUser: jest.fn(() => 'v1'),
    } as never;
    const feedTracking = {} as never;
    const svc = new SitesFeedService(feedQuery, feedCache, feedPreferences, feedTracking);

    await expect(
      svc.findAll({ lat: 41.6, page: 1, limit: 20, radiusKm: 10, sort: 'hybrid' } as never),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});
