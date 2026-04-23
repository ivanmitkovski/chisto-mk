import {
  Body,
  Controller,
  Delete,
  Get,
  MessageEvent,
  NotFoundException,
  Param,
  Patch,
  Post,
  Query,
  Sse,
  UploadedFile,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor, FilesInterceptor } from '@nestjs/platform-express';
import * as multer from 'multer';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConsumes,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { Observable, interval, merge } from 'rxjs';
import { map } from 'rxjs/operators';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { CheckEventConflictQueryDto } from './dto/check-event-conflict-query.dto';
import { CreatePublicEventDto } from './dto/create-public-event.dto';
import { EventAnalyticsResponseDto } from './dto/event-analytics-response.dto';
import { ListEventParticipantsResponseDto } from './dto/event-participant-row.dto';
import { FieldBatchDto } from './dto/field-batch.dto';
import { ListEventParticipantsQueryDto } from './dto/list-event-participants-query.dto';
import { FindEventQueryDto } from './dto/find-event-query.dto';
import { ListEventsQueryDto } from './dto/list-events-query.dto';
import { PatchEventLifecycleDto } from './dto/patch-event-lifecycle.dto';
import { PatchEventReminderDto } from './dto/patch-event-reminder.dto';
import { PatchLiveImpactDto } from './dto/patch-live-impact.dto';
import { PatchPublicEventDto } from './dto/patch-public-event.dto';
import { EventImpactReceiptResponseDto } from './dto/event-impact-receipt-response.dto';
import { EventPublicShareCardResponseDto } from './dto/event-public-share-card.dto';
import { EventEvidenceService } from './event-evidence.service';
import { EventLiveImpactService } from './event-live-impact.service';
import { EventRouteSegmentsService } from './event-route-segments.service';
import { EventsFieldBatchService } from './events-field-batch.service';
import { EventRouteWaypointsBodyDto } from './dto/event-route-waypoint.dto';
import { EventsService } from './events.service';
import { EventImpactReceiptService } from './event-impact-receipt.service';

const LIVE_IMPACT_SSE_HEARTBEAT_MS = 30_000;

@ApiTags('events')
@Controller('events')
@UseGuards(ThrottlerGuard)
export class EventsController {
  constructor(
    private readonly eventsService: EventsService,
    private readonly liveImpact: EventLiveImpactService,
    private readonly evidence: EventEvidenceService,
    private readonly routeSegments: EventRouteSegmentsService,
    private readonly fieldBatchService: EventsFieldBatchService,
    private readonly impactReceipt: EventImpactReceiptService,
  ) {}

  @Get()
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'List cleanup events (approved public events plus caller’s own pending drafts)',
  })
  @ApiOkResponse({ description: 'Paginated events' })
  list(@CurrentUser() user: AuthenticatedUser, @Query() query: ListEventsQueryDto) {
    return this.eventsService.list(user, query);
  }

  @Get('check-conflict')
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Preview duplicate schedule at a site (buffered overlap; excludes cancelled/completed)',
  })
  @ApiOkResponse({
    description: '{ hasConflict, conflictingEvent? }',
  })
  checkConflict(
    @CurrentUser() _user: AuthenticatedUser,
    @Query() query: CheckEventConflictQueryDto,
  ) {
    return this.eventsService.checkScheduleConflictPreview(query);
  }

  @Post('field-batch')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 30 } })
  @ApiOperation({ summary: 'Apply queued field-mode operations (offline sync)' })
  @ApiOkResponse({ description: 'Batch outcome' })
  applyFieldBatch(@CurrentUser() user: AuthenticatedUser, @Body() dto: FieldBatchDto) {
    return this.fieldBatchService.applyBatch(user, dto);
  }

  @Get(':id/participants')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @ApiOperation({ summary: 'List event joiners (paginated); organizer is not included' })
  @ApiOkResponse({ description: 'Participants page', type: ListEventParticipantsResponseDto })
  listParticipants(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Query() query: ListEventParticipantsQueryDto,
  ) {
    return this.eventsService.listParticipants(id, user, query);
  }

  @Get(':id/live-impact')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @ApiOperation({ summary: 'Aggregated live impact counters for an event' })
  @ApiOkResponse({ description: 'Live impact snapshot' })
  getLiveImpact(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.liveImpact.getSnapshot(id, user);
  }

  @Get(':id/live-impact/stream')
  @Sse()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 30 } })
  @ApiOperation({ summary: 'SSE stream for live impact updates on this event' })
  streamLiveImpact(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ): Observable<MessageEvent> {
    const live$ = this.liveImpact.watchLiveImpactSse(id, user);
    const heartbeat$ = interval(LIVE_IMPACT_SSE_HEARTBEAT_MS).pipe(
      map(() => ({ data: { type: 'heartbeat' } } as MessageEvent)),
    );
    return merge(live$, heartbeat$);
  }

  @Patch(':id/live-impact')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @ApiOperation({ summary: 'Update organizer-reported live impact (organizer only)' })
  @ApiOkResponse({ description: 'Updated snapshot' })
  async patchLiveImpact(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: PatchLiveImpactDto,
  ) {
    await this.liveImpact.patch(id, dto, user);
    return this.eventsService.findOne(id, user);
  }

  @Get(':id/evidence')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @ApiOperation({ summary: 'List structured evidence photos for an event' })
  @ApiOkResponse({ description: 'Evidence rows with signed URLs' })
  listEvidence(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.evidence.listForEvent(id, user);
  }

  @Post(':id/evidence')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 20 } })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: multer.memoryStorage(),
      limits: { fileSize: 10 * 1024 * 1024 },
    }),
  )
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Upload one evidence image (organizer only); form field `kind`: BEFORE|AFTER|FIELD' })
  @ApiOkResponse({ description: 'Created evidence row' })
  uploadEvidence(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @UploadedFile() file: Express.Multer.File,
    @Body('kind') kind: string,
  ) {
    return this.evidence.addPhoto(id, user, file, kind);
  }

  @Delete(':id/evidence/:photoId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 30 } })
  @ApiOperation({ summary: 'Delete an evidence photo (organizer only)' })
  @ApiOkResponse({ description: 'No content semantics — returns { ok: true }' })
  async deleteEvidence(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Param('photoId') photoId: string,
  ): Promise<{ ok: true }> {
    await this.evidence.deletePhoto(id, photoId, user);
    return { ok: true };
  }

  @Get(':id/route')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @ApiOperation({ summary: 'List route segments for an event' })
  @ApiOkResponse({ description: 'Route segments' })
  listRoute(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.routeSegments.listForEvent(id, user);
  }

  @Patch(':id/route')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 20 } })
  @ApiOperation({ summary: 'Replace route waypoints (organizer only)' })
  @ApiOkResponse({ description: 'Updated segments' })
  patchRoute(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() body: EventRouteWaypointsBodyDto,
  ) {
    return this.routeSegments.replaceWaypoints(id, user, body.waypoints);
  }

  @Post(':id/route/segments/:segmentId/claim')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 40 } })
  @ApiOperation({ summary: 'Claim an open route segment (joined volunteer)' })
  @ApiOkResponse({ description: 'Updated segments' })
  claimRouteSegment(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') _eventId: string,
    @Param('segmentId') segmentId: string,
  ) {
    return this.routeSegments.claimSegment(segmentId, user);
  }

  @Post(':id/route/segments/:segmentId/complete')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 40 } })
  @ApiOperation({ summary: 'Mark a route segment completed (claimer or organizer)' })
  @ApiOkResponse({ description: 'Updated segments' })
  completeRouteSegment(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') _eventId: string,
    @Param('segmentId') segmentId: string,
  ) {
    return this.routeSegments.completeSegment(segmentId, user);
  }

  @Get(':id/share-card')
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @ApiOperation({
    summary:
      'Public share card for HTTPS `/events/:id` landing (approved moderation, non-cancelled lifecycle)',
  })
  @ApiOkResponse({ type: EventPublicShareCardResponseDto })
  @ApiNotFoundResponse({ description: 'Event not found or not publicly visible' })
  getPublicShareCard(@Param('id') id: string) {
    const trimmed = id.trim();
    const uuidLike =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidLike.test(trimmed)) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }
    return this.eventsService.findPublicShareCard(trimmed);
  }

  @Get(':id/impact-receipt')
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Impact receipt (aggregate check-ins, bags, signed evidence/after photos; no roster). Not available for upcoming or cancelled.',
  })
  @ApiOkResponse({ description: 'Impact receipt payload', type: EventImpactReceiptResponseDto })
  @ApiBadRequestResponse({
    description: 'Receipt not available for this lifecycle (e.g. upcoming, cancelled)',
    schema: {
      example: {
        code: 'EVENTS_IMPACT_RECEIPT_NOT_AVAILABLE',
        message: 'Impact receipt is not available for this event state.',
      },
    },
  })
  getImpactReceipt(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.impactReceipt.buildForViewer(id, user);
  }

  @Get(':id')
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Get event detail (approved public events plus caller’s own pending drafts)',
  })
  @ApiOkResponse({ description: 'Event payload (mobile-shaped JSON)' })
  findOne(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Query() geo: FindEventQueryDto,
  ) {
    return this.eventsService.findOne(id, user, geo);
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 20 } })
  @ApiOperation({ summary: 'Create cleanup event (PENDING for citizens, APPROVED for staff)' })
  @ApiOkResponse({ description: 'Created event' })
  create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreatePublicEventDto) {
    return this.eventsService.create(dto, user);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 40 } })
  @ApiOperation({ summary: 'Update event (organizer only)' })
  @ApiOkResponse({ description: 'Updated event' })
  patch(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: PatchPublicEventDto,
  ) {
    return this.eventsService.patchEvent(id, dto, user);
  }

  @Post(':id/join')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Join event' })
  @ApiBadRequestResponse({
    description:
      'Join not allowed (e.g. after join window, organizer, or not approved). Join closes 15 minutes after scheduled start.',
    schema: {
      example: {
        code: 'EVENT_JOIN_WINDOW_CLOSED',
        message:
          'Joining is closed for this event. Volunteers could join until 15 minutes after the scheduled start.',
      },
    },
  })
  @ApiOkResponse({
    description: 'Event payload (same as GET /events/:id) plus pointsAwarded for this join',
  })
  join(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.eventsService.join(id, user);
  }

  @Delete(':id/join')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Leave event' })
  @ApiOkResponse({ description: 'Event with isJoined false' })
  leave(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.eventsService.leave(id, user);
  }

  @Patch(':id/status')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Transition lifecycle status (organizer only)' })
  @ApiOkResponse({ description: 'Updated event' })
  patchStatus(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: PatchEventLifecycleDto,
  ) {
    return this.eventsService.patchLifecycle(id, dto, user);
  }

  @Patch(':id/reminder')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Set participant reminder' })
  @ApiOkResponse({ description: 'Updated event' })
  patchReminder(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: PatchEventReminderDto,
  ) {
    return this.eventsService.patchReminder(id, dto, user);
  }

  @Get(':id/analytics')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Attendance analytics for an event (organizer only)' })
  @ApiOkResponse({ description: 'Event analytics data', type: EventAnalyticsResponseDto })
  getAnalytics(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.eventsService.getAnalytics(id, user);
  }

  @Post(':id/after-images')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 15 } })
  @UseInterceptors(
    FilesInterceptor('files', 10, {
      storage: multer.memoryStorage(),
      limits: { fileSize: 10 * 1024 * 1024 },
    }),
  )
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Upload after-cleanup photos (organizer only)' })
  @ApiOkResponse({ description: 'Updated event with signed image URLs' })
  uploadAfterImages(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @UploadedFiles() files: Express.Multer.File[],
  ) {
    return this.eventsService.appendAfterImages(id, files ?? [], user);
  }
}
