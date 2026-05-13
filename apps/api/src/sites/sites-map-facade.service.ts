import { Injectable } from '@nestjs/common';
import { ListSitesMapQueryDto } from './dto/list-sites-map-query.dto';
import { SiteMapSearchDto } from './dto/site-map-search.dto';
import { SitesMapQueryService } from './sites-map-query.service';
import { SitesMapAdminTimelineService } from './sites-map-admin-timeline.service';
import { SitesSearchService } from './sites-search.service';
import { MapMvtTilesService } from './map/map-mvt-tiles.service';

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

  findAllForMap(query: ListSitesMapQueryDto) {
    return this.sitesMapQuery.findAllForMap(query);
  }

  resolveMapDataVersion(query: ListSitesMapQueryDto) {
    return this.sitesMapQuery.resolveMapDataVersion(query);
  }

  findClustersForMap(query: ListSitesMapQueryDto) {
    return this.sitesMapQuery.findClustersForMap(query);
  }

  findHeatmapForMap(query: ListSitesMapQueryDto) {
    return this.sitesMapQuery.findHeatmapForMap(query);
  }

  searchMapSites(dto: SiteMapSearchDto) {
    return this.sitesSearch.searchMapSites(dto);
  }

  getAdminMapTimeline(at?: string) {
    return this.mapAdminTimeline.getAdminMapTimeline(at);
  }

  async getMapMvtTile(z: number, x: number, y: number): Promise<{ buffer: Buffer; etag: string }> {
    return this.mapMvtTiles.getTileOrThrow(z, x, y);
  }
}
