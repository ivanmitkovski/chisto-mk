import { ListSitesMapQueryDto } from '../dto/list-sites-map-query.dto';
import { MapQueryValidatorService } from './map-query-validator.service';

export function resolveMapSiteBounds(
  query: ListSitesMapQueryDto,
  validator: MapQueryValidatorService,
): {
  minLat: number;
  maxLat: number;
  minLng: number;
  maxLng: number;
} {
  if (validator.hasViewportBounds(query)) {
    return {
      minLat: query.minLat!,
      maxLat: query.maxLat!,
      minLng: query.minLng!,
      maxLng: query.maxLng!,
    };
  }
  const radiusMeters = (query.radiusKm ?? 10) * 1000;
  const metersPerDegreeLat = 111_320;
  const deltaLat = radiusMeters / metersPerDegreeLat;
  const metersPerDegreeLng =
    Math.cos((query.lat * Math.PI) / 180) * metersPerDegreeLat || metersPerDegreeLat;
  const deltaLng = radiusMeters / metersPerDegreeLng;
  return {
    minLat: query.lat - deltaLat,
    maxLat: query.lat + deltaLat,
    minLng: query.lng - deltaLng,
    maxLng: query.lng + deltaLng,
  };
}
