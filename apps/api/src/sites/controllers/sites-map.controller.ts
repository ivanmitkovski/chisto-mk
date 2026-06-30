import {
  Controller,
  Get,
  Headers,
  Param,
  ParseIntPipe,
  Query,
  Res,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import type { Response } from 'express';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
} from '@nestjs/swagger';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { OptionalJwtAuthGuard } from '../../auth/guards/optional-jwt-auth.guard';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ListSitesMapQueryDto } from '../dto/list-sites-map-query.dto';
import { SitesMapFacadeService } from '../services/sites-map-facade.service';
import { loadFeatureFlags } from '../../config/feature-flags';
import { weakEtagForJson } from '../http/map-etag';
import { MapRateLimitGuard } from '../http/map-rate-limit.guard';
import { MapHttpTracingInterceptor } from '../../observability/util/map-http-tracing.interceptor';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';
import { MapViewerContext } from '../util/site-visibility.helper';
import { MapOfflineRegionsService } from '../map/offline/map-offline-regions.service';
import { MapOfflineRegionIdParam } from '../map/offline/dto/map-offline-region-id.param';

const featureFlags = loadFeatureFlags();

@ApiTags('sites')
@ApiStandardHttpErrorResponses()
@Controller('sites')
export class SitesMapController {
  constructor(
    private readonly sitesMapFacade: SitesMapFacadeService,
    private readonly offlineRegions: MapOfflineRegionsService,
  ) {}

  @Get('map')
  @UseInterceptors(new MapHttpTracingInterceptor())
  @UseGuards(MapRateLimitGuard, OptionalJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List sites for map view with geo bounds and high limit' })
  @ApiOkResponse({ description: 'Sites for map fetched successfully' })
  @ApiBadRequestResponse({ description: 'Invalid map viewport or geo params' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  async findAllForMap(
    @Query() query: ListSitesMapQueryDto,
    @Headers('if-none-match') ifNoneMatch: string | undefined,
    @Res({ passthrough: true }) res: Response,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    const viewer: MapViewerContext = { viewerUserId: user?.userId ?? null };
    if (featureFlags.mapEtagEnabled) {
      const mapDataVersion = await this.sitesMapFacade.resolveMapDataVersion(query, viewer);
      const etag = weakEtagForJson({
        kind: 'map',
        version: mapDataVersion,
        query: {
          detail: query.detail,
          status: query.status ?? null,
          includeArchived: query.includeArchived ?? false,
          lat: query.lat,
          lng: query.lng,
          radiusKm: query.radiusKm,
          minLat: query.minLat ?? null,
          maxLat: query.maxLat ?? null,
          minLng: query.minLng ?? null,
          maxLng: query.maxLng ?? null,
          zoom: query.zoom ?? null,
          limit: query.limit,
        },
      });
      if (ifNoneMatch?.trim() === etag) {
        res.setHeader('ETag', etag);
        res.setHeader('Cache-Control', 'private, max-age=4, stale-while-revalidate=20');
        res.status(304);
        return undefined;
      }
      res.setHeader('ETag', etag);
      res.setHeader('Cache-Control', 'private, max-age=4, stale-while-revalidate=20');
    }
    const body = await this.sitesMapFacade.findAllForMap(query, viewer);
    return body;
  }

  @Get('map/clusters')
  @UseInterceptors(new MapHttpTracingInterceptor())
  @UseGuards(MapRateLimitGuard, OptionalJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get aggregated map clusters for dense marker view' })
  @ApiOkResponse({ description: 'Map clusters fetched successfully' })
  @ApiBadRequestResponse({ description: 'Invalid map viewport or geo params' })
  async findClustersForMap(
    @Query() query: ListSitesMapQueryDto,
    @Headers('if-none-match') ifNoneMatch: string | undefined,
    @Res({ passthrough: true }) res: Response,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    const viewer: MapViewerContext = { viewerUserId: user?.userId ?? null };
    const body = await this.sitesMapFacade.findClustersForMap(query, viewer);
    if (featureFlags.mapEtagEnabled) {
      const etag = weakEtagForJson(body);
      if (ifNoneMatch?.trim() === etag) {
        res.status(304);
        return undefined;
      }
      res.setHeader('ETag', etag);
      res.setHeader('Cache-Control', 'private, max-age=4, stale-while-revalidate=20');
    }
    return body;
  }

  @Get('map/heatmap')
  @UseInterceptors(new MapHttpTracingInterceptor())
  @UseGuards(MapRateLimitGuard, OptionalJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get map heatmap density cells by viewport/zoom' })
  @ApiOkResponse({ description: 'Map heatmap fetched successfully' })
  @ApiBadRequestResponse({ description: 'Invalid map viewport or geo params' })
  async findHeatmapForMap(
    @Query() query: ListSitesMapQueryDto,
    @Headers('if-none-match') ifNoneMatch: string | undefined,
    @Res({ passthrough: true }) res: Response,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    const viewer: MapViewerContext = { viewerUserId: user?.userId ?? null };
    const body = await this.sitesMapFacade.findHeatmapForMap(query, viewer);
    if (featureFlags.mapEtagEnabled) {
      const etag = weakEtagForJson(body);
      if (ifNoneMatch?.trim() === etag) {
        res.status(304);
        return undefined;
      }
      res.setHeader('ETag', etag);
      res.setHeader('Cache-Control', 'private, max-age=4, stale-while-revalidate=20');
    }
    return body;
  }

  @Get('map/tiles/:z/:x/:y.mvt')
  @UseGuards(MapRateLimitGuard, OptionalJwtAuthGuard)
  @ApiOperation({ summary: 'Mapbox vector tile (MVT) for sites/clusters overlay' })
  async getMapMvtTile(
    @Param('z', ParseIntPipe) z: number,
    @Param('x', ParseIntPipe) x: number,
    @Param('y', ParseIntPipe) y: number,
    @Headers('if-none-match') ifNoneMatch: string | undefined,
    @CurrentUser() user: AuthenticatedUser | undefined,
    @Res() res: Response,
  ): Promise<void> {
    const viewerUserId = user?.userId ?? null;
    const { buffer, etag } = await this.sitesMapFacade.getMapMvtTile(z, x, y, viewerUserId);

    if (ifNoneMatch && ifNoneMatch === etag) {
      res.status(304).end();
      return;
    }

    res.setHeader('Content-Type', 'application/vnd.mapbox-vector-tile');
    res.setHeader('ETag', etag);
    const cacheControl = viewerUserId
      ? 'private, max-age=60, stale-while-revalidate=300'
      : 'public, max-age=60, s-maxage=600, stale-while-revalidate=86400';
    res.setHeader('Cache-Control', cacheControl);
    res.setHeader('Surrogate-Key', `map-tile z=${z}`);
    res.send(buffer);
  }

  @Get('map/offline/manifest')
  @UseGuards(MapRateLimitGuard, OptionalJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Offline map region package manifest (flag-gated)' })
  @ApiOkResponse({ description: 'Offline regions manifest' })
  getOfflineMapManifest() {
    return this.offlineRegions.getManifest();
  }

  @Get('map/offline/regions/:regionId/download-url')
  @UseGuards(MapRateLimitGuard, OptionalJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Presigned download URL for an offline map region package' })
  @ApiOkResponse({ description: 'Signed region package URL' })
  getOfflineMapRegionDownloadUrl(@Param() params: MapOfflineRegionIdParam) {
    return this.offlineRegions.getRegionDownloadUrl(params.regionId);
  }
}
