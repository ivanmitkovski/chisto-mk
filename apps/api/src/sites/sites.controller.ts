import { createHash } from 'node:crypto';

import {
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  MessageEvent as NestMessageEvent,
  Param,
  Patch,
  Post,
  Query,
  Res,
  Sse,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import type { Response } from 'express';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { ADMIN_PANEL_ROLES, ADMIN_WRITE_ROLES } from '../auth/admin-roles';
import { CurrentUser } from '../auth/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { CreateSiteDto } from './dto/create-site.dto';
import { ListSitesMapQueryDto } from './dto/list-sites-map-query.dto';
import { ListSiteCommentsQueryDto } from './dto/list-site-comments-query.dto';
import { ListSiteMediaQueryDto } from './dto/list-site-media-query.dto';
import { ListSitesQueryDto } from './dto/list-sites-query.dto';
import { CreateSiteCommentDto } from './dto/create-site-comment.dto';
import { ShareSiteDto } from './dto/share-site.dto';
import { SubmitFeedFeedbackDto } from './dto/submit-feed-feedback.dto';
import { TrackFeedEventDto } from './dto/track-feed-event.dto';
import { UpdateSiteCommentDto } from './dto/update-site-comment.dto';
import { UpdateSiteStatusDto } from './dto/update-site-status.dto';
import { SitesService } from './sites.service';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { Observable, concat, defer, finalize, from, interval, map, merge } from 'rxjs';
import { SiteEventsService } from '../admin-events/site-events.service';
import { ObservabilityStore } from '../observability/observability.store';

@ApiTags('sites')
@Controller('sites')
export class SitesController {
  private static readonly HEARTBEAT_INTERVAL_MS = 30_000;

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
  create(@Body() dto: CreateSiteDto) {
    return this.sitesService.create(dto);
  }

  @Get()
  @UseGuards(ThrottlerGuard)
  @Throttle({ default: { limit: 90, ttl: 60_000 } })
  @ApiOperation({ summary: 'List sites with optional filters' })
  @ApiOkResponse({ description: 'Sites fetched successfully' })
  findAll(@Query() query: ListSitesQueryDto, @CurrentUser() user?: AuthenticatedUser) {
    return this.sitesService.findAll(query, user);
  }

  @Post('feed/events')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 240, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Track feed telemetry event' })
  trackFeedEvent(@Body() dto: TrackFeedEventDto, @CurrentUser() user: AuthenticatedUser) {
    return this.sitesService.trackFeedEvent(dto, user);
  }

  @Get('map')
  @UseGuards(ThrottlerGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiOperation({ summary: 'List sites for map view with geo bounds and high limit' })
  @ApiOkResponse({ description: 'Sites for map fetched successfully' })
  async findAllForMap(
    @Query() query: ListSitesMapQueryDto,
    @Res({ passthrough: true }) res: Response,
  ) {
    const body = await this.sitesService.findAllForMap(query);
    const etag = SitesController.weakEtagForMapBody(body);
    res.setHeader('ETag', etag);
    res.setHeader('Cache-Control', 'private, max-age=4, stale-while-revalidate=20');
    return body;
  }

  private static weakEtagForMapBody(body: {
    data: Array<{ id: string; updatedAt?: Date | string }>;
  }): string {
    const h = createHash('sha1');
    for (const row of body.data) {
      h.update(row.id);
      const u =
        row.updatedAt instanceof Date
          ? row.updatedAt.toISOString()
          : String(row.updatedAt ?? '');
      h.update(u);
    }
    return `W/"${h.digest('hex').slice(0, 24)}"`;
  }

  @Get('events')
  @Sse()
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Server-Sent Events stream for site updates (mobile map)' })
  streamSiteEvents(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @Headers('last-event-id') lastEventId?: string,
  ): Observable<NestMessageEvent> {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }
    return defer(() => {
      ObservabilityStore.recordMapSseConnected();
      const replayEvents = this.siteEventsService.getReplaySince(lastEventId);
      if (replayEvents.length > 0) {
        ObservabilityStore.recordMapSseReplayEvents(replayEvents.length);
      }
      const toSseEvent = (
        event: { eventId: string; type: string } & Record<string, unknown>,
      ): NestMessageEvent => {
        ObservabilityStore.recordMapSseEventEmitted();
        return {
          data: event as object,
          type: event.type,
          id: event.eventId,
        };
      };
      const replay$ = from(replayEvents).pipe(map((event) => toSseEvent(event)));
      const live$ = this.siteEventsService.getEvents().pipe(
        map((event) => toSseEvent(event)),
      );
      const heartbeat$ = interval(SitesController.HEARTBEAT_INTERVAL_MS).pipe(
        map(() => ({ data: { type: 'heartbeat' } } as NestMessageEvent)),
      );
      return concat(replay$, merge(live$, heartbeat$)).pipe(
        finalize(() => {
          ObservabilityStore.recordMapSseDisconnected();
        }),
      );
    });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get site details with reports' })
  @ApiOkResponse({ description: 'Site fetched successfully' })
  findOne(@Param('id') id: string, @CurrentUser() user?: AuthenticatedUser) {
    return this.sitesService.findOne(id, user);
  }

  @Get(':id/media')
  @ApiOperation({ summary: 'Get all site media with pagination' })
  @ApiOkResponse({ description: 'Site media fetched successfully' })
  findMedia(
    @Param('id') id: string,
    @Query() query: ListSiteMediaQueryDto,
  ) {
    return this.sitesService.findSiteMedia(id, query);
  }

  @Get(':id/comments')
  @ApiOperation({ summary: 'Get comments for site' })
  @ApiOkResponse({ description: 'Site comments fetched successfully' })
  findComments(
    @Param('id') id: string,
    @Query() query: ListSiteCommentsQueryDto,
    @CurrentUser() user?: AuthenticatedUser,
  ) {
    return this.sitesService.findSiteComments(id, query, user);
  }

  @Post(':id/comments')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create comment for site' })
  @ApiCreatedResponse({ description: 'Site comment created successfully' })
  createComment(
    @Param('id') id: string,
    @Body() dto: CreateSiteCommentDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.sitesService.createSiteComment(id, dto, user);
  }

  @Post(':id/comments/:commentId/like')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Like a site comment' })
  likeComment(
    @Param('id') id: string,
    @Param('commentId') commentId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.sitesService.likeSiteComment(id, commentId, user);
  }

  @Delete(':id/comments/:commentId/like')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Unlike a site comment' })
  unlikeComment(
    @Param('id') id: string,
    @Param('commentId') commentId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.sitesService.unlikeSiteComment(id, commentId, user);
  }

  @Patch(':id/comments/:commentId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Edit a site comment' })
  editComment(
    @Param('id') id: string,
    @Param('commentId') commentId: string,
    @Body() dto: UpdateSiteCommentDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.sitesService.updateSiteComment(id, commentId, dto, user);
  }

  @Delete(':id/comments/:commentId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete a site comment' })
  deleteComment(
    @Param('id') id: string,
    @Param('commentId') commentId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.sitesService.deleteSiteComment(id, commentId, user);
  }

  @Post(':id/upvote')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Upvote site' })
  upvote(@Param('id') id: string, @CurrentUser() user: AuthenticatedUser) {
    return this.sitesService.upvoteSite(id, user);
  }

  @Delete(':id/upvote')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Remove upvote from site' })
  removeUpvote(@Param('id') id: string, @CurrentUser() user: AuthenticatedUser) {
    return this.sitesService.removeSiteUpvote(id, user);
  }

  @Post(':id/save')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Save site' })
  save(@Param('id') id: string, @CurrentUser() user: AuthenticatedUser) {
    return this.sitesService.saveSite(id, user);
  }

  @Delete(':id/save')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Remove saved site' })
  unsave(@Param('id') id: string, @CurrentUser() user: AuthenticatedUser) {
    return this.sitesService.unsaveSite(id, user);
  }

  @Post(':id/share')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 120, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Track site share event' })
  shareSite(
    @Param('id') id: string,
    @Body() dto: ShareSiteDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.sitesService.shareSite(id, dto, user);
  }

  @Post(':id/feed-feedback')
  @UseGuards(JwtAuthGuard, ThrottlerGuard)
  @Throttle({ default: { limit: 180, ttl: 60_000 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Submit feed relevance feedback for a site' })
  submitFeedFeedback(
    @Param('id') id: string,
    @Body() dto: SubmitFeedFeedbackDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.sitesService.submitFeedFeedback(id, dto, user);
  }

  @Patch(':id/status')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update canonical site lifecycle status' })
  @ApiOkResponse({ description: 'Site status updated successfully' })
  updateStatus(
    @Param('id') id: string,
    @Body() dto: UpdateSiteStatusDto,
    @CurrentUser() admin: AuthenticatedUser,
  ) {
    return this.sitesService.updateStatus(id, dto, admin);
  }
}
