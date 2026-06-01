import { Injectable } from '@nestjs/common';
import { ListSitesMapQueryDto } from './dto/list-sites-map-query.dto';
import { SiteMapSearchDto } from './dto/site-map-search.dto';
import { SitesMapQueryService } from './sites-map-query.service';
import { SitesMapAdminTimelineService } from './sites-map-admin-timeline.service';
import { SitesSearchService } from './sites-search.service';
import { MapMvtTilesService } from './map/map-mvt-tiles.service';
import { MapViewerContext } from './map/map-site-visibility.helper';

/**
 * Map read and admin-map surface area split from the public sites HTTP layer to keep
 * main sites facade within service-size guard method budgets.
 */
@Injectable()
export class SitesMapFacadeService {
  constructor(
    private readonly sitesMapQuery: SitesMapQueryService,
    private readonly mapMvtTiles: MapMvtTilesService,
    private readonly mapAdminTimeline: SitesMapAdminTimelineService,
    private readonly sitesSearch: SitesSearchService,
  ) {}

  findAllForMap(query: ListSitesMapQueryDto, viewer?: MapViewerContext) {
    return this.sitesMapQuery.findAllForMap(query, viewer);
  }

  resolveMapDataVersion(query: ListSitesMapQueryDto, viewer?: MapViewerContext) {
    return this.sitesMapQuery.resolveMapDataVersion(query, viewer);
  }

  findClustersForMap(query: ListSitesMapQueryDto, viewer?: MapViewerContext) {
    return this.sitesMapQuery.findClustersForMap(query, viewer);
  }

  findHeatmapForMap(query: ListSitesMapQueryDto, viewer?: MapViewerContext) {
    return this.sitesMapQuery.findHeatmapForMap(query, viewer);
  }

  searchMapSites(dto: SiteMapSearchDto, viewer?: MapViewerContext) {
    return this.sitesSearch.searchMapSites(dto, viewer);
  }

  getAdminMapTimeline(at?: string) {
    return this.mapAdminTimeline.getAdminMapTimeline(at);
  }

  async getMapMvtTile(z: number, x: number, y: number): Promise<{ buffer: Buffer; etag: string }> {
    return this.mapMvtTiles.getTileOrThrow(z, x, y);
  }
}
