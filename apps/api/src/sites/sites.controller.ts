import {
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  MessageEvent as NestMessageEvent,
  Param,
  ParseIntPipe,
  Patch,
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
import { ADMIN_PANEL_ROLES, ADMIN_WRITE_ROLES } from '../auth/admin-roles';
import { CurrentUser } from '../auth/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../auth/optional-jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { BulkSitesDto } from './dto/bulk-sites.dto';
import { CreateSiteDto } from './dto/create-site.dto';
import { ListSitesMapQueryDto } from './dto/list-sites-map-query.dto';
import { ListSiteCommentsQueryDto } from './dto/list-site-comments-query.dto';
import { ListSiteMediaQueryDto } from './dto/list-site-media-query.dto';
import { ListSiteUpvotesQueryDto } from './dto/list-site-upvotes-query.dto';
import { ListSitesQueryDto } from './dto/list-sites-query.dto';
import { CreateSiteCommentDto } from './dto/create-site-comment.dto';
import { SiteMapSearchDto } from './dto/site-map-search.dto';
import { ShareSiteDto } from './dto/share-site.dto';
import { SiteShareAttributionEventDto } from './dto/site-share-attribution-event.dto';
import { SiteShareLinkRequestDto } from './dto/site-share-link-request.dto';
import { SiteShareLinkResponseDto } from './dto/site-share-link-response.dto';
import { SubmitFeedFeedbackDto } from './dto/submit-feed-feedback.dto';
import { TrackFeedEventDto } from './dto/track-feed-event.dto';
import { UpdateSiteCommentDto } from './dto/update-site-comment.dto';
import { UpdateSiteArchiveDto } from './dto/update-site-archive.dto';
import { UpdateSiteStatusDto } from './dto/update-site-status.dto';
import { SiteCommentLikeResponseDto } from './dto/site-comment-like-response.dto';
import {
  SiteCommentTreeNodeResponseDto,
  SiteCommentsListResponseDto,
} from './dto/site-comment-tree-response.dto';
import { SiteDetailResponseDto } from './dto/site-detail-response.dto';
import { SiteEngagementSnapshotResponseDto } from './dto/site-engagement-snapshot-response.dto';
import { SiteFeedListResponseDto } from './dto/site-list-item-response.dto';
import { SiteMediaListResponseDto } from './dto/site-media-response.dto';
import { SiteUpvotersListResponseDto } from './dto/site-upvoters-response.dto';
import { SitesService } from './sites.service';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { Observable } from 'rxjs';
import { SiteEventsService } from '../admin-events/site-events.service';
import { ParseCuidPipe } from '../common/pipes/parse-cuid.pipe';
import { loadFeatureFlags } from '../config/feature-flags';
import { weakEtagForJson } from './http/map-etag';
import { clientIp } from './http/client-ip';

const featureFlags = loadFeatureFlags();
import {
  normalizeShareClickEvent,
  normalizeShareOpenEvent,
} from './http/share-attribution-normalizer';
import { buildSiteEventsStream } from './http/site-events-stream';
import { MapRateLimitGuard } from './http/map-rate-limit.guard';
import { MapHttpTracingInterceptor } from '../observability/map-http-tracing.interceptor';

@ApiTags('sites')
@Controller('sites')
export class SitesController {
  constructor(
    private readonly sitesService: SitesService,
    private readonly siteEventsService: SiteEventsService,
  ) {}

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new pollution site' })
  @ApiCreatedResponse({ description: 'Site created successfully' })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiForbiddenResponse({ description: 'Caller is not an admin' })
  create(@Body() dto: CreateSiteDto) {
    return this.sitesService.create(dto);
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
    const result = await this.sitesService.findAll(query, user);
    const variant = user ? this.sitesService.getFeedVariantForUser(user.userId) : 'v1';
    res.setHeader('x-feed-variant', variant);
    res.setHeader('x-feed-experiment', 'feed_v2_ranking');
    return result;
  }

  @Post('feed/events')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 240, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Track feed telemetry event' })
  @ApiOkResponse({ description: 'Event recorded' })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  trackFeedEvent(@Body() dto: TrackFeedEventDto, @CurrentUser() user: AuthenticatedUser) {
    return this.sitesService.trackFeedEvent(dto, user);
  }

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
      const mapDataVersion = await this.sitesService.resolveMapDataVersion(query);
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
    const body = await this.sitesService.findAllForMap(query);
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
    const body = await this.sitesService.findClustersForMap(query);
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
    const body = await this.sitesService.findHeatmapForMap(query);
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
    const { buffer, etag } = await this.sitesService.getMapMvtTile(z, x, y);

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

  @Post('search')
  @UseGuards(MapRateLimitGuard)
  @ApiOperation({ summary: 'Search sites for map (text + optional geo intent)' })
  @ApiOkResponse({ description: 'Search results' })
  async searchSitesForMap(@Body() dto: SiteMapSearchDto) {
    return this.sitesService.searchMapSites(dto);
  }

  @Post('admin/bulk')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Bulk site moderation actions' })
  @ApiOkResponse({ description: 'Bulk update applied' })
  async bulkSites(@Body() dto: BulkSitesDto, @CurrentUser() admin: AuthenticatedUser) {
    return this.sitesService.bulkSites(dto, admin);
  }

  @Get('admin/map/timeline')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Operator map timeline probe (24h replay stub)' })
  async adminMapTimeline(@Query('at') at?: string) {
    return this.sitesService.getAdminMapTimeline(at);
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

  @Get(':id')
  @UseGuards(ThrottlerGuard, OptionalJwtAuthGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get site details with reports' })
  @ApiOkResponse({ description: 'Site fetched successfully', type: SiteDetailResponseDto })
  @ApiNotFoundResponse({ description: 'Site not found' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  findOne(@Param('id', ParseCuidPipe) id: string, @CurrentUser() user?: AuthenticatedUser) {
    return this.sitesService.findOne(id, user);
  }

  @Get(':id/media')
  @UseGuards(ThrottlerGuard, OptionalJwtAuthGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all site media with pagination' })
  @ApiOkResponse({ description: 'Site media fetched successfully', type: SiteMediaListResponseDto })
  @ApiNotFoundResponse({ description: 'Site not found' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  findMedia(
    @Param('id', ParseCuidPipe) id: string,
    @Query() query: ListSiteMediaQueryDto,
  ) {
    return this.sitesService.findSiteMedia(id, query);
  }

  @Get(':id/comments')
  @UseGuards(ThrottlerGuard, OptionalJwtAuthGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get comments for site' })
  @ApiOkResponse({ description: 'Site comments fetched successfully', type: SiteCommentsListResponseDto })
  @ApiNotFoundResponse({ description: 'Site not found' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  findComments(
    @Param('id', ParseCuidPipe) id: string,
    @Query() query: ListSiteCommentsQueryDto,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    return this.sitesService.findSiteComments(id, query, user);
  }

  @Get(':id/upvotes')
  @UseGuards(ThrottlerGuard, OptionalJwtAuthGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List users who upvoted this site' })
  @ApiOkResponse({ description: 'Site upvotes fetched successfully', type: SiteUpvotersListResponseDto })
  @ApiNotFoundResponse({ description: 'Site not found' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  findUpvotes(
    @Param('id', ParseCuidPipe) id: string,
    @Query() query: ListSiteUpvotesQueryDto,
    @CurrentUser() _user?: AuthenticatedUser,
  ) {
    return this.sitesService.findSiteUpvotes(id, query);
  }

  @Post(':id/comments')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create comment for site' })
  @ApiCreatedResponse({ description: 'Site comment created successfully', type: SiteCommentTreeNodeResponseDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiBadRequestResponse({ description: 'Empty body or invalid parent' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  createComment(
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: CreateSiteCommentDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.sitesService.createSiteComment(id, dto, user);
  }

  @Post(':id/comments/:commentId/like')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Like a site comment' })
  @ApiOkResponse({ description: 'Like applied', type: SiteCommentLikeResponseDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiNotFoundResponse({ description: 'Comment not found' })
  likeComment(
    @Param('id', ParseCuidPipe) id: string,
    @Param('commentId', ParseCuidPipe) commentId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.sitesService.likeSiteComment(id, commentId, user);
  }

  @Delete(':id/comments/:commentId/like')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Unlike a site comment' })
  @ApiOkResponse({ description: 'Like removed', type: SiteCommentLikeResponseDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiNotFoundResponse({ description: 'Comment not found' })
  unlikeComment(
    @Param('id', ParseCuidPipe) id: string,
    @Param('commentId', ParseCuidPipe) commentId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.sitesService.unlikeSiteComment(id, commentId, user);
  }

  @Patch(':id/comments/:commentId')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Edit a site comment' })
  @ApiOkResponse({ description: 'Comment updated', type: SiteCommentTreeNodeResponseDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiForbiddenResponse({ description: 'Not the author' })
  @ApiNotFoundResponse({ description: 'Comment not found' })
  @ApiBadRequestResponse({ description: 'Empty body' })
  editComment(
    @Param('id', ParseCuidPipe) id: string,
    @Param('commentId', ParseCuidPipe) commentId: string,
    @Body() dto: UpdateSiteCommentDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.sitesService.updateSiteComment(id, commentId, dto, user);
  }

  @Delete(':id/comments/:commentId')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete a site comment' })
  @ApiOkResponse({ description: 'Comment soft-deleted' })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiForbiddenResponse({ description: 'Not the author' })
  @ApiNotFoundResponse({ description: 'Comment not found' })
  deleteComment(
    @Param('id', ParseCuidPipe) id: string,
    @Param('commentId', ParseCuidPipe) commentId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.sitesService.deleteSiteComment(id, commentId, user);
  }

  @Post(':id/upvote')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Upvote site' })
  @ApiOkResponse({ description: 'Engagement snapshot', type: SiteEngagementSnapshotResponseDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  upvote(@Param('id', ParseCuidPipe) id: string, @CurrentUser() user: AuthenticatedUser) {
    return this.sitesService.upvoteSite(id, user);
  }

  @Delete(':id/upvote')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Remove upvote from site' })
  @ApiOkResponse({ description: 'Engagement snapshot', type: SiteEngagementSnapshotResponseDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  removeUpvote(@Param('id', ParseCuidPipe) id: string, @CurrentUser() user: AuthenticatedUser) {
    return this.sitesService.removeSiteUpvote(id, user);
  }

  @Post(':id/save')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Save site' })
  @ApiOkResponse({ description: 'Engagement snapshot', type: SiteEngagementSnapshotResponseDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  save(@Param('id', ParseCuidPipe) id: string, @CurrentUser() user: AuthenticatedUser) {
    return this.sitesService.saveSite(id, user);
  }

  @Delete(':id/save')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Remove saved site' })
  @ApiOkResponse({ description: 'Engagement snapshot', type: SiteEngagementSnapshotResponseDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  unsave(@Param('id', ParseCuidPipe) id: string, @CurrentUser() user: AuthenticatedUser) {
    return this.sitesService.unsaveSite(id, user);
  }

  @Post(':id/share')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Track site share event' })
  @ApiOkResponse({ description: 'Engagement snapshot', type: SiteEngagementSnapshotResponseDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  shareSite(
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: ShareSiteDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.sitesService.shareSite(id, dto, user);
  }

  @Post(':id/share-link')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 90, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Issue signed share link for a pollution site' })
  @ApiOkResponse({ type: SiteShareLinkResponseDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  issueShareLink(
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: SiteShareLinkRequestDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.sitesService.issueShareLink(id, dto, user);
  }

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
    return this.sitesService.ingestShareAttributionEvent({
      dto: normalizeShareClickEvent(dto),
      ipAddress: clientIp(req, xff),
      userAgent: userAgent?.trim() || null,
      openedByUserId: undefined,
    });
  }

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
    return this.sitesService.ingestShareAttributionEvent({
      dto: normalizeShareOpenEvent(dto),
      ipAddress: clientIp(req, xff),
      userAgent: userAgent?.trim() || null,
      openedByUserId: user?.userId,
    });
  }

  @Post(':id/feed-feedback')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 180, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Submit feed relevance feedback for a site' })
  @ApiOkResponse({ description: 'Feedback recorded' })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  submitFeedFeedback(
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: SubmitFeedFeedbackDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.sitesService.submitFeedFeedback(id, dto, user);
  }

  @Patch(':id/status')
  @UseGuards(JwtAuthGuard, RolesGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update canonical site lifecycle status' })
  @ApiOkResponse({ description: 'Site status updated successfully' })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiForbiddenResponse({ description: 'Caller is not an admin' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  @ApiBadRequestResponse({ description: 'Invalid status transition' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  updateStatus(
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: UpdateSiteStatusDto,
    @CurrentUser() admin: AuthenticatedUser,
  ) {
    return this.sitesService.updateStatus(id, dto, admin);
  }

  @Patch(':id/archive')
  @UseGuards(JwtAuthGuard, RolesGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Archive or unarchive site from default map visibility' })
  @ApiOkResponse({ description: 'Site archive moderation updated successfully' })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT' })
  @ApiForbiddenResponse({ description: 'Caller is not an admin' })
  @ApiNotFoundResponse({ description: 'Site not found' })
  @ApiBadRequestResponse({ description: 'Invalid archive moderation payload' })
  @ApiTooManyRequestsResponse({ description: 'Too many requests' })
  updateArchiveStatus(
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: UpdateSiteArchiveDto,
    @CurrentUser() admin: AuthenticatedUser,
  ) {
    return this.sitesService.updateArchiveStatus(id, dto, admin);
  }
}
