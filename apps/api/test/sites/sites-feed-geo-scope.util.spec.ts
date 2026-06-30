import { SiteFeedGeoScope } from '../../src/sites/dto/list-sites-query.dto';
import {
  DISCOVERY_DISTANCE_RADIUS_FLOOR_KM,
  discoveryRankingRadiusKm,
  resolveFeedGeoScope,
} from '../../src/sites/util/sites-feed-geo-scope.util';

describe('sites-feed-geo-scope.util', () => {
  const originalEnv = process.env.FEED_DISCOVERY_ENABLED;

  afterEach(() => {
    if (originalEnv === undefined) {
      delete process.env.FEED_DISCOVERY_ENABLED;
    } else {
      process.env.FEED_DISCOVERY_ENABLED = originalEnv;
    }
  });

  it('resolveFeedGeoScope honors discovery when kill switch is on', () => {
    delete process.env.FEED_DISCOVERY_ENABLED;
    expect(
      resolveFeedGeoScope({ scope: SiteFeedGeoScope.DISCOVERY } as any),
    ).toBe(SiteFeedGeoScope.DISCOVERY);
  });

  it('resolveFeedGeoScope falls back to local when kill switch disabled', () => {
    process.env.FEED_DISCOVERY_ENABLED = 'false';
    expect(
      resolveFeedGeoScope({ scope: SiteFeedGeoScope.DISCOVERY } as any),
    ).toBe(SiteFeedGeoScope.LOCAL);
  });

  it('discoveryRankingRadiusKm applies floor', () => {
    expect(discoveryRankingRadiusKm(50)).toBe(DISCOVERY_DISTANCE_RADIUS_FLOOR_KM);
    expect(discoveryRankingRadiusKm(150)).toBe(150);
  });
});
