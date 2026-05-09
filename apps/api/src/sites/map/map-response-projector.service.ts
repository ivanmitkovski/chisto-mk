import { Injectable } from '@nestjs/common';
import { distanceInMeters } from '../../common/utils/distance';
import { ListSitesMapQueryDto } from '../dto/list-sites-map-query.dto';
import { MapListApiRow, MapProjectionRow, MapQueryMode, MapResponse } from './map-types';
import { MapQueryValidatorService } from './map-query-validator.service';

@Injectable()
export class MapResponseProjectorService {
  private static readonly SIGNED_MEDIA_CLIENT_BUFFER_MS = 55 * 60 * 1000;

  constructor(private readonly validator: MapQueryValidatorService) {}

  async buildResponse(input: {
    query: ListSitesMapQueryDto;
    rows: MapProjectionRow[];
    usedViewportBbox: boolean;
    mapMode?: 'sites' | 'clusters' | 'mixed';
  }): Promise<MapResponse> {
    const { query, rows, usedViewportBbox } = input;
    const isLite = query.detail === 'lite';
    const data = rows.map((site) => this.projectRow(site, query, isLite));
    const filtered = usedViewportBbox ? data : this.filterMapRowsToExactRadius(data, query);
    const signedMediaExpiresAt = new Date(
      Date.now() + MapResponseProjectorService.SIGNED_MEDIA_CLIENT_BUFFER_MS,
    ).toISOString();
    const latestUpdateMs = filtered.reduce<number>((maxMs, row) => {
      const rowMs = Date.parse(row.updatedAt);
      return rowMs > maxMs ? rowMs : maxMs;
    }, 0);

    return {
      data: filtered,
      meta: {
        signedMediaExpiresAt,
        serverTime: new Date().toISOString(),
        queryMode: this.resolveQueryMode(query),
        dataVersion: latestUpdateMs.toString(36),
        ...(input.mapMode ? { mapMode: input.mapMode } : {}),
      },
    };
  }

  private projectRow(
    site: MapProjectionRow,
    query: ListSitesMapQueryDto,
    isLite: boolean,
  ): MapListApiRow {
    const distanceKm = this.computeMapDistanceKm(query, site.latitude, site.longitude);
    return {
      id: site.siteId,
      latitude: site.latitude,
      longitude: site.longitude,
      address: site.address,
      description: site.description,
      status: site.status as MapListApiRow['status'],
      upvotesCount: isLite ? 0 : site.upvotesCount,
      commentsCount: isLite ? 0 : site.commentsCount,
      savesCount: isLite ? 0 : site.savesCount,
      sharesCount: isLite ? 0 : site.sharesCount,
      reportCount: site.reportCount,
      latestReportTitle: isLite ? null : site.latestReportTitle,
      latestReportDescription: isLite ? null : site.latestReportDescription,
      latestReportCategory: isLite ? null : site.pollutionCategory,
      latestReportCreatedAt: isLite ? null : site.latestReportAt?.toISOString() ?? null,
      latestReportNumber: isLite ? null : site.latestReportNumber,
      ...(site.thumbnailUrl ? { latestReportMediaUrls: [site.thumbnailUrl] } : {}),
      ...(distanceKm != null ? { distanceKm } : {}),
      createdAt: site.siteCreatedAt.toISOString(),
      updatedAt: site.siteUpdatedAt.toISOString(),
    };
  }

  private computeMapDistanceKm(
    query: ListSitesMapQueryDto,
    latitude: number | null,
    longitude: number | null,
  ): number | undefined {
    if (latitude == null || longitude == null) return undefined;
    return distanceInMeters(query.lat, query.lng, latitude, longitude) / 1000;
  }

  private filterMapRowsToExactRadius(rows: MapListApiRow[], query: ListSitesMapQueryDto): MapListApiRow[] {
    const radiusMeters = (query.radiusKm ?? 10) * 1000;
    return rows.filter((row) => {
      if (this.validator.hasViewportBounds(query)) {
        return (
          row.latitude != null &&
          row.longitude != null &&
          row.latitude >= query.minLat! &&
          row.latitude <= query.maxLat! &&
          row.longitude >= query.minLng! &&
          row.longitude <= query.maxLng!
        );
      }
      if (row.distanceKm == null) return false;
      return row.distanceKm * 1000 <= radiusMeters;
    });
  }

  private resolveQueryMode(query: ListSitesMapQueryDto): MapQueryMode {
    return this.validator.hasViewportBounds(query) ? 'viewport' : 'radius';
  }
}
