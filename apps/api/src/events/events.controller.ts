import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import * as multer from 'multer';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConsumes,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { CurrentUser } from '../auth/current-user.decorator';
import { ParseCuidPipe } from '../common/pipes/parse-cuid.pipe';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ListEventParticipantsResponseDto } from './dto/event-participant-row.dto';
import { ListEventParticipantsQueryDto } from './dto/list-event-participants-query.dto';
import { FindEventQueryDto } from './dto/find-event-query.dto';
import { PatchEventLifecycleDto } from './dto/patch-event-lifecycle.dto';
import { PatchEventReminderDto } from './dto/patch-event-reminder.dto';
import { PatchPublicEventDto } from './dto/patch-public-event.dto';
import { EventImpactReceiptResponseDto } from './dto/event-impact-receipt-response.dto';
import { EventPublicShareCardResponseDto } from './dto/event-public-share-card.dto';
import { JoinEventResponseDto } from './dto/events-openapi-responses.dto';
import { EventMobileResponseDto } from './dto/event-mobile-response.dto';
import { EventAnalyticsResponseDto } from './dto/event-analytics-response.dto';
import { EventsAfterImagesService } from './events-after-images.service';
import { EventsAnalyticsService } from './events-analytics.service';
import { EventsLifecycleService } from './events-lifecycle.service';
import { EventsParticipationService } from './events-participation.service';
import { EventsQueryService } from './events-query.service';
import { EventsShareCardQueryService } from './events-share-card-query.service';
import { EventsUpdateService } from './events-update.service';
import { EventImpactReceiptService } from './event-impact-receipt.service';
import { ApiEventsJwtStandardErrors } from './events-openapi.decorators';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';

@ApiTags('events')
@ApiStandardHttpErrorResponses()
@Controller('events')
@UseGuards(ThrottlerGuard)
export class EventsController {
  constructor(
    private readonly query: EventsQueryService,
    private readonly updates: EventsUpdateService,
    private readonly lifecycle: EventsLifecycleService,
    private readonly participation: EventsParticipationService,
    private readonly afterImages: EventsAfterImagesService,
    private readonly analytics: EventsAnalyticsService,
    private readonly shareCard: EventsShareCardQueryService,
    private readonly impactReceipt: EventImpactReceiptService,
  ) {}

  @Get(':id/participants')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @ApiOperation({ summary: 'List event joiners (paginated); organizer is not included' })
  @ApiOkResponse({ description: 'Participants page', type: ListEventParticipantsResponseDto })
  @ApiEventsJwtStandardErrors()
  listParticipants(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseCuidPipe) id: string,
    @Query() query: ListEventParticipantsQueryDto,
  ) {
    return this.query.listParticipants(id, user, query);
  }

  @Get(':id/share-card')
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @ApiOperation({
    summary:
      'Public share card for HTTPS `/events/:id` landing (approved moderation, non-cancelled lifecycle)',
  })
  @ApiOkResponse({ type: EventPublicShareCardResponseDto })
  @ApiNotFoundResponse({ description: 'Event not found or not publicly visible' })
  @ApiBadRequestResponse({
    description: 'Malformed event id',
    schema: { example: { code: 'INVALID_CUID', message: 'Invalid resource id' } },
  })
  @ApiResponse({
    status: 429,
    description: 'Too many requests (throttled)',
    schema: {
      example: {
        code: 'TOO_MANY_REQUESTS',
        message: 'Too many requests. Please wait and try again.',
        timestamp: '2026-04-16T12:00:00.000Z',
        requestId: '01JF…',
      },
    },
  })
  getPublicShareCard(@Param('id', ParseCuidPipe) id: string) {
    return this.shareCard.findPublicShareCard(id);
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
  @ApiEventsJwtStandardErrors()
  getImpactReceipt(@CurrentUser() user: AuthenticatedUser, @Param('id', ParseCuidPipe) id: string) {
    return this.impactReceipt.buildForViewer(id, user);
  }

  @Get(':id')
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Get event detail (approved public events plus caller’s own pending drafts)',
  })
  @ApiOkResponse({ description: 'Event payload (mobile-shaped JSON)', type: EventMobileResponseDto })
  @ApiEventsJwtStandardErrors()
  findOne(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseCuidPipe) id: string,
    @Query() geo: FindEventQueryDto,
  ) {
    return this.query.findOne(id, user, geo);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 40 } })
  @ApiOperation({ summary: 'Update event (organizer only)' })
  @ApiOkResponse({ description: 'Updated event', type: EventMobileResponseDto })
  @ApiEventsJwtStandardErrors({ include409: true })
  patch(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: PatchPublicEventDto,
  ) {
    return this.updates.patchEvent(id, dto, user);
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
    type: JoinEventResponseDto,
  })
  @ApiEventsJwtStandardErrors({ include409: true })
  join(@CurrentUser() user: AuthenticatedUser, @Param('id', ParseCuidPipe) id: string) {
    return this.participation.join(id, user);
  }

  @Delete(':id/join')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Leave event' })
  @ApiOkResponse({ description: 'Event with isJoined false', type: EventMobileResponseDto })
  @ApiEventsJwtStandardErrors()
  leave(@CurrentUser() user: AuthenticatedUser, @Param('id', ParseCuidPipe) id: string) {
    return this.participation.leave(id, user);
  }

  @Patch(':id/status')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Transition lifecycle status (organizer only)' })
  @ApiOkResponse({ description: 'Updated event', type: EventMobileResponseDto })
  @ApiEventsJwtStandardErrors()
  patchStatus(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: PatchEventLifecycleDto,
  ) {
    return this.lifecycle.patchLifecycle(id, dto, user);
  }

  @Patch(':id/reminder')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Set participant reminder' })
  @ApiOkResponse({ description: 'Updated event', type: EventMobileResponseDto })
  @ApiEventsJwtStandardErrors()
  patchReminder(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: PatchEventReminderDto,
  ) {
    return this.participation.patchReminder(id, dto, user);
  }

  @Get(':id/analytics')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Attendance analytics for an event (organizer only)' })
  @ApiOkResponse({ description: 'Event analytics data', type: EventAnalyticsResponseDto })
  @ApiEventsJwtStandardErrors()
  getAnalytics(@CurrentUser() user: AuthenticatedUser, @Param('id', ParseCuidPipe) id: string) {
    return this.analytics.getAnalytics(id, user);
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
  @ApiOkResponse({ description: 'Updated event with signed image URLs', type: EventMobileResponseDto })
  @ApiEventsJwtStandardErrors()
  uploadAfterImages(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseCuidPipe) id: string,
    @UploadedFiles() files: Express.Multer.File[],
  ) {
    return this.afterImages.appendAfterImages(id, files ?? [], user);
  }
}
