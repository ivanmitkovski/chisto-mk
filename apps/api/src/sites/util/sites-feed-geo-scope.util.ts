import { ListSitesQueryDto, SiteFeedGeoScope } from '../dto/list-sites-query.dto';

/** Effective geo scope after server kill switch. */
export function resolveFeedGeoScope(query: ListSitesQueryDto): SiteFeedGeoScope {
  if (process.env.FEED_DISCOVERY_ENABLED === 'false') {
    return SiteFeedGeoScope.LOCAL;
  }
  return query.scope ?? SiteFeedGeoScope.LOCAL;
}

/** Distance normalization floor for discovery ranking (km). */
export const DISCOVERY_DISTANCE_RADIUS_FLOOR_KM = 120;

export function discoveryRankingRadiusKm(radiusKm: number | undefined): number {
  return Math.max(radiusKm ?? 10, DISCOVERY_DISTANCE_RADIUS_FLOOR_KM);
}
