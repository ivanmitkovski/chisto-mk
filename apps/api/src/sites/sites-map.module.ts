import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AdminRealtimeModule } from '../admin-realtime/admin-realtime.module';
import { FeatureFlagsModule } from '../feature-flags/feature-flags.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { SitesMapController } from './controllers/sites-map.controller';
import { SitesMapQueryService } from './services/sites-map-query.service';
import { SitesMapFacadeService } from './services/sites-map-facade.service';
import { SitesMapSearchQueryService } from './services/sites-map-search-query.service';
import { SitesSearchService } from './services/sites-search.service';
import { SitesMapAdminTimelineService } from './services/sites-map-admin-timeline.service';
import { MapRateLimitGuard } from './http/map-rate-limit.guard';
import { MapCacheService } from './map/map-cache.service';
import { MapQueryValidatorService } from './map/map-query-validator.service';
import { MapResponseProjectorService } from './map/map-response-projector.service';
import { MapSiteRepositoryAggregatesService } from './map/map-site-repository-aggregates.service';
import { MapSiteRepositoryService } from './map/map-site-repository.service';
import { MapSiteRepositorySitesService } from './map/map-site-repository-sites.service';
import { MapObservabilityService } from './map/map-observability.service';
import { MapProjectionDiffService } from './map/map-projection-diff.service';
import { MapProjectionUpdaterService } from './map/map-projection-updater.service';
import { MapProjectionWriterService } from './map/map-projection-writer.service';
import { MapLifecycleCronService } from './map/map-lifecycle-cron.service';
import { MapMvtTilesFallbackService } from './map/map-mvt-tiles-fallback.service';
import { MapMvtTilesPostgisService } from './map/map-mvt-tiles-postgis.service';
import { MapMvtTilesService } from './map/map-mvt-tiles.service';
import { MapOfflineRegionsService } from './map/offline/map-offline-regions.service';
import { TypesenseModule } from './search/typesense/typesense.module';

@Module({
  imports: [ConfigModule, ReportsUploadModule, AdminRealtimeModule, FeatureFlagsModule, TypesenseModule],
  controllers: [SitesMapController],
  providers: [
    SitesMapQueryService,
    MapCacheService,
    MapQueryValidatorService,
    MapResponseProjectorService,
    MapSiteRepositorySitesService,
    MapSiteRepositoryAggregatesService,
    MapSiteRepositoryService,
    MapObservabilityService,
    MapProjectionDiffService,
    MapProjectionWriterService,
    MapProjectionUpdaterService,
    MapLifecycleCronService,
    MapMvtTilesPostgisService,
    MapMvtTilesFallbackService,
    MapMvtTilesService,
    SitesMapSearchQueryService,
    SitesSearchService,
    SitesMapAdminTimelineService,
    SitesMapFacadeService,
    MapRateLimitGuard,
    MapOfflineRegionsService,
  ],
  exports: [SitesMapFacadeService, MapCacheService, SitesMapQueryService],
})
export class SitesMapModule {}
