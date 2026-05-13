import { Injectable } from '@nestjs/common';
import { ListSitesMapQueryDto } from '../dto/list-sites-map-query.dto';
import { MapProjectionRow } from './map-types';
import { MapSiteRepositoryAggregatesService } from './map-site-repository-aggregates.service';
import { MapSiteRepositorySitesService } from './map-site-repository-sites.service';

@Injectable()
export class MapSiteRepositoryService {
  constructor(
    private readonly sites: MapSiteRepositorySitesService,
    private readonly aggregates: MapSiteRepositoryAggregatesService,
  ) {}

  findSites(
    query: ListSitesMapQueryDto,
    limit: number,
  ): Promise<{ rows: MapProjectionRow[]; usedViewportBbox: boolean; usedFallback: boolean }> {
    return this.sites.findSites(query, limit);
  }

  resolveDataVersion(query: ListSitesMapQueryDto): Promise<string> {
    return this.sites.resolveDataVersion(query);
  }

  findClusters(
    query: ListSitesMapQueryDto,
    zoom: number,
  ): Promise<
    Array<{
      clusterKey: string;
      clusterId: string;
      latitude: number;
      longitude: number;
      count: number;
      siteIds: string[];
    }>
  > {
    return this.aggregates.findClusters(query, zoom);
  }

  findHeatmap(
    query: ListSitesMapQueryDto,
    zoom: number,
  ): Promise<Array<{ cellKey: string; latitude: number; longitude: number; intensity: number }>> {
    return this.aggregates.findHeatmap(query, zoom);
  }
}
