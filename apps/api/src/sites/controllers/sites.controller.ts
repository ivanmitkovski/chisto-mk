import { Idempotent } from '../../common/idempotency/idempotency.decorator';
import {
  Body,
  Controller,
  Get,
  Headers,
  MessageEvent as NestMessageEvent,
  Post,
  Query,
  Req,
  Res,
  Sse,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { ADMIN_PANEL_ROLES, ADMIN_WRITE_ROLES } from '../../auth/constants/admin-roles';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../../auth/guards/optional-jwt-auth.guard';
import { Roles } from '../../auth/decorators/roles.decorator';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { BulkSitesDto } from '../dto/bulk-sites.dto';
import { CreateSiteDto } from '../dto/create-site.dto';
import { ListSitesQueryDto } from '../dto/list-sites-query.dto';
import { SiteMapSearchDto } from '../dto/site-map-search.dto';
import { SiteShareAttributionEventDto } from '../dto/site-share-attribution-event.dto';
import { TrackFeedEventDto } from '../dto/track-feed-event.dto';
import { SiteFeedListResponseDto } from '../dto/site-list-item-response.dto';
import { SitesAdminService } from '../services/sites-admin.service';
import { SitesFeedService } from '../services/sites-feed.service';
import { SitesSavedListService } from '../services/sites-saved-list.service';
import { SiteEngagementService } from '../services/site-engagement.service';
import { PaginationQueryDto20 } from '../../common/dto/pagination-query.dto';
import { SitesMapFacadeService } from '../services/sites-map-facade.service';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { Observable } from 'rxjs';
import { SiteEventsService } from '../../admin-realtime/services/site-events.service';
import { clientIp } from '../http/client-ip';
import {
  normalizeShareClickEvent,
  normalizeShareOpenEvent,
} from '../http/share-attribution-normalizer';
import { buildSiteEventsStream } from '../http/site-events-stream';
import { MapRateLimitGuard } from '../http/map-rate-limit.guard';
import { MapHttpTracingInterceptor } from '../../observability/util/map-http-tracing.interceptor';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';

@ApiTags('sites')
@ApiStandardHttpErrorResponses()
@Controller('sites')
export class SitesController {
  constructor(
    private readonly sitesAdmin: SitesAdminService,
    private readonly sitesFeed: SitesFeedService,
    private readonly sitesSavedList: SitesSavedListService,
    private readonly siteEngagement: SiteEngagementService,
    private readonly sitesMapFacade: SitesMapFacadeService,
    private readonly siteEventsService: SiteEventsService,
  ) {}

  @Idempotent('sites_sites_74')
  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new pollution site' })
  @ApiCreatedResponse({ description: 'Site created successfully' })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiForbiddenResponse({ description: 'Caller is not an admin' })
  create(@Body() dto: CreateSiteDto) {
    return this.sitesAdmin.create(dto);
  }

  @Get('saved')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 90, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List sites saved by the current user' })
  @ApiOkResponse({ description: 'Saved sites fetched successfully', type: SiteFeedListResponseDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  listSaved(
    @Query() query: PaginationQueryDto20,
    @CurrentUser() user: AuthenticatedUser,
    @Query('lat') latRaw?: string,
    @Query('lng') lngRaw?: string,
  ) {
    const latNum = latRaw != null && latRaw.trim() !== '' ? Number(latRaw) : Number.NaN;
    const lngNum = lngRaw != null && lngRaw.trim() !== '' ? Number(lngRaw) : Number.NaN;
    const geo: { lat?: number; lng?: number } = {};
    if (Number.isFinite(latNum)) geo.lat = latNum;
    if (Number.isFinite(lngNum)) geo.lng = lngNum;
    return this.sitesSavedList.listSavedForUser(
      user,
      query,
      Object.keys(geo).length > 0 ? geo : undefined,
    );
  }

  @Get()
  @UseGuards(ThrottlerGuard, OptionalJwtAuthGuard)
  @Throttle({ default: { limit: 90, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List sites with optional filters' })
  @ApiOkResponse({ description: 'Sites fetched successfully', type: SiteFeedListResponseDto })
  @ApiBadRequestResponse({ description: 'Invalid geo query or filters' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  async findAll(
    @Query() query: ListSitesQueryDto,
    @CurrentUser() user: AuthenticatedUser | undefined,
    @Res({ passthrough: true }) res: Response,
  ) {
    const result = await this.sitesFeed.findAll(query, user);
    const variant = user ? this.sitesFeed.getFeedVariantForUser(user.userId) : 'v1';
    res.setHeader('x-feed-variant', variant);
    res.setHeader('x-feed-experiment', 'feed_v2_ranking');
    return result;
  }

  @Idempotent('sites_sites_132')
  @Post('feed/events')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 240, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Track feed telemetry event' })
  @ApiOkResponse({ description: 'Event recorded' })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  trackFeedEvent(@Body() dto: TrackFeedEventDto, @CurrentUser() user: AuthenticatedUser) {
    return this.sitesFeed.trackFeedEvent(dto, user);
  }

  @Idempotent('sites_sites_144')
  @Post('search')
  @UseGuards(MapRateLimitGuard, OptionalJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Search sites for map (text + optional geo intent)' })
  @ApiOkResponse({ description: 'Search results' })
  async searchSitesForMap(
    @Body() dto: SiteMapSearchDto,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    return this.sitesMapFacade.searchMapSites(dto, {
      viewerUserId: user?.userId ?? null,
    });
  }

  @Idempotent('sites_sites_152')
  @Post('admin/bulk')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Bulk site moderation actions' })
  @ApiOkResponse({ description: 'Bulk update applied' })
  async bulkSites(@Body() dto: BulkSitesDto, @CurrentUser() admin: AuthenticatedUser) {
    return this.sitesAdmin.bulkSites(dto, admin);
  }

  @Get('admin/map/timeline')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Operator map timeline probe (24h replay stub)' })
  async adminMapTimeline(@Query('at') at?: string) {
    return this.sitesMapFacade.getAdminMapTimeline(at);
  }

  @Get('events')
  @Sse()
  @UseInterceptors(new MapHttpTracingInterceptor())
  @UseGuards(MapRateLimitGuard, JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Server-Sent Events stream for site updates (mobile map)' })
  streamSiteEvents(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @Headers('last-event-id') lastEventId?: string,
  ): Observable<NestMessageEvent> {
    return buildSiteEventsStream(this.siteEventsService, user, lastEventId);
  }

  @Idempotent('sites_sites_184')
  @Post('share-events/click')
  @UseGuards(ThrottlerGuard)
  @Throttle({ default: { limit: 180, ttl: 60_000 } })
  @ApiOperation({ summary: 'Ingest a web click/view attribution event for a site share link' })
  @ApiOkResponse({ description: 'Attribution event accepted' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  ingestShareClick(
    @Body() dto: SiteShareAttributionEventDto,
    @Req() req: Request,
    @Headers('x-forwarded-for') xff?: string,
    @Headers('user-agent') userAgent?: string,
  ) {
    return this.siteEngagement.ingestAttributionEvent({
      ...normalizeShareClickEvent(dto),
      ipAddress: clientIp(req, xff),
      userAgent: userAgent?.trim() || null,
      openedByUserId: undefined,
    });
  }

  @Idempotent('sites_sites_204')
  @Post('share-events/open')
  @UseGuards(ThrottlerGuard, OptionalJwtAuthGuard)
  @Throttle({ default: { limit: 180, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Ingest an app open attribution event for a site share link' })
  @ApiOkResponse({ description: 'Attribution event accepted' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  ingestShareOpen(
    @Body() dto: SiteShareAttributionEventDto,
    @Req() req: Request,
    @CurrentUser() user?: AuthenticatedUser,
    @Headers('x-forwarded-for') xff?: string,
    @Headers('user-agent') userAgent?: string,
  ) {
    return this.siteEngagement.ingestAttributionEvent({
      ...normalizeShareOpenEvent(dto),
      ipAddress: clientIp(req, xff),
      userAgent: userAgent?.trim() || null,
      openedByUserId: user?.userId,
    });
  }
}
