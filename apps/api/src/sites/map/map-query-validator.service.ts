import { BadRequestException, Injectable } from '@nestjs/common';
import { ListSitesMapQueryDto } from '../dto/list-sites-map-query.dto';

@Injectable()
export class MapQueryValidatorService {
  private static readonly MACEDONIA_BOUNDS = {
    minLat: 40.85,
    maxLat: 42.4,
    minLng: 20.4,
    maxLng: 23.2,
  } as const;

  private readonly strictBoundsEnabled =
    (process.env.MAP_STRICT_BOUNDS ?? 'false').trim().toLowerCase() === 'true';

  hasViewportBounds(query: ListSitesMapQueryDto): boolean {
    return (
      query.minLat != null &&
      query.maxLat != null &&
      query.minLng != null &&
      query.maxLng != null
    );
  }

  validateQuery(query: ListSitesMapQueryDto): void {
    this.validateViewport(query);
    this.validateBusinessBounds(query);
  }

  private validateViewport(query: ListSitesMapQueryDto): void {
    const hasAnyBounds =
      query.minLat != null ||
      query.maxLat != null ||
      query.minLng != null ||
      query.maxLng != null;
    const hasAllBounds = this.hasViewportBounds(query);
    if (hasAnyBounds && !hasAllBounds) {
      throw new BadRequestException({
        code: 'INVALID_MAP_VIEWPORT',
        message: 'All map viewport bounds must be provided together.',
      });
    }
    if (hasAllBounds && (query.minLat! > query.maxLat! || query.minLng! > query.maxLng!)) {
      throw new BadRequestException({
        code: 'INVALID_MAP_VIEWPORT',
        message: 'Map viewport bounds are invalid.',
      });
    }
    if (hasAllBounds) {
      const latSpan = Math.abs(query.maxLat! - query.minLat!);
      const lngSpan = Math.abs(query.maxLng! - query.minLng!);
      if (latSpan > 4 || lngSpan > 4) {
        throw new BadRequestException({
          code: 'MAP_VIEWPORT_TOO_WIDE',
          message: 'Map viewport span exceeds the maximum allowed range.',
          details: { maxSpanDegrees: 4, latSpan, lngSpan },
        });
      }
    }
  }

  private validateBusinessBounds(query: ListSitesMapQueryDto): void {
    if (!this.strictBoundsEnabled) {
      return;
    }
    const b = MapQueryValidatorService.MACEDONIA_BOUNDS;
    const inBounds = (lat: number, lng: number) =>
      lat >= b.minLat && lat <= b.maxLat && lng >= b.minLng && lng <= b.maxLng;
    if (!inBounds(query.lat, query.lng)) {
      throw new BadRequestException({
        code: 'MAP_CENTER_OUT_OF_BOUNDS',
        message: 'Map center is outside supported geography.',
      });
    }
    if (this.hasViewportBounds(query)) {
      const viewportInBounds =
        query.minLat! >= b.minLat &&
        query.maxLat! <= b.maxLat &&
        query.minLng! >= b.minLng &&
        query.maxLng! <= b.maxLng;
      if (!viewportInBounds) {
        throw new BadRequestException({
          code: 'MAP_VIEWPORT_OUT_OF_BOUNDS',
          message: 'Map viewport is outside supported geography.',
        });
      }
    }
  }
}
