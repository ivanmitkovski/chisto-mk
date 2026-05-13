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
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
} from '@nestjs/swagger';
import { ListSitesMapQueryDto } from './dto/list-sites-map-query.dto';
import { SitesMapFacadeService } from './sites-map-facade.service';
import { loadFeatureFlags } from '../config/feature-flags';
import { weakEtagForJson } from './http/map-etag';
import { MapRateLimitGuard } from './http/map-rate-limit.guard';
import { MapHttpTracingInterceptor } from '../observability/map-http-tracing.interceptor';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';

const featureFlags = loadFeatureFlags();

@ApiTags('sites')
@ApiStandardHttpErrorResponses()
@Controller('sites')
export class SitesMapController {
  constructor(private readonly sitesMapFacade: SitesMapFacadeService) {}

  @Get('map')
  @UseInterceptors(new MapHttpTracingInterceptor())
  @UseGuards(MapRateLimitGuard)
  @ApiOperation({ summary: 'List sites for map view with geo bounds and high limit' })
  @ApiOkResponse({ description: 'Sites for map fetched successfully' })
  @ApiBadRequestResponse({ description: 'Invalid map viewport or geo params' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  async findAllForMap(
    @Query() query: ListSitesMapQueryDto,
    @Headers('if-none-match') ifNoneMatch: string | undefined,
    @Res({ passthrough: true }) res: Response,
  ) {
    if (featureFlags.mapEtagEnabled) {
      const mapDataVersion = await this.sitesMapFacade.resolveMapDataVersion(query);
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
    const body = await this.sitesMapFacade.findAllForMap(query);
    return body;
  }

  @Get('map/clusters')
  @UseInterceptors(new MapHttpTracingInterceptor())
  @UseGuards(MapRateLimitGuard)
  @ApiOperation({ summary: 'Get aggregated map clusters for dense marker view' })
  @ApiOkResponse({ description: 'Map clusters fetched successfully' })
  @ApiBadRequestResponse({ description: 'Invalid map viewport or geo params' })
  async findClustersForMap(
    @Query() query: ListSitesMapQueryDto,
    @Headers('if-none-match') ifNoneMatch: string | undefined,
    @Res({ passthrough: true }) res: Response,
  ) {
    const body = await this.sitesMapFacade.findClustersForMap(query);
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
  @UseGuards(MapRateLimitGuard)
  @ApiOperation({ summary: 'Get map heatmap density cells by viewport/zoom' })
  @ApiOkResponse({ description: 'Map heatmap fetched successfully' })
  @ApiBadRequestResponse({ description: 'Invalid map viewport or geo params' })
  async findHeatmapForMap(
    @Query() query: ListSitesMapQueryDto,
    @Headers('if-none-match') ifNoneMatch: string | undefined,
    @Res({ passthrough: true }) res: Response,
  ) {
    const body = await this.sitesMapFacade.findHeatmapForMap(query);
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
  @UseGuards(MapRateLimitGuard)
  @ApiOperation({ summary: 'Mapbox vector tile (MVT) for sites/clusters overlay' })
  async getMapMvtTile(
    @Param('z', ParseIntPipe) z: number,
    @Param('x', ParseIntPipe) x: number,
    @Param('y', ParseIntPipe) y: number,
    @Headers('if-none-match') ifNoneMatch: string | undefined,
    @Res() res: Response,
  ): Promise<void> {
    const { buffer, etag } = await this.sitesMapFacade.getMapMvtTile(z, x, y);

    if (ifNoneMatch && ifNoneMatch === etag) {
      res.status(304).end();
      return;
    }

    res.setHeader('Content-Type', 'application/vnd.mapbox-vector-tile');
    res.setHeader('ETag', etag);
    res.setHeader(
      'Cache-Control',
      'public, max-age=60, s-maxage=600, stale-while-revalidate=86400',
    );
    res.setHeader('Surrogate-Key', `map-tile z=${z}`);
    res.send(buffer);
  }
}
