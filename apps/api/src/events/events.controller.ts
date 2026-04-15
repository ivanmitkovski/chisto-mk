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
  ApiBearerAuth,
  ApiConsumes,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { CreatePublicEventDto } from './dto/create-public-event.dto';
import { EventAnalyticsResponseDto } from './dto/event-analytics-response.dto';
import { ListEventParticipantsResponseDto } from './dto/event-participant-row.dto';
import { ListEventParticipantsQueryDto } from './dto/list-event-participants-query.dto';
import { ListEventsQueryDto } from './dto/list-events-query.dto';
import { PatchEventLifecycleDto } from './dto/patch-event-lifecycle.dto';
import { PatchEventReminderDto } from './dto/patch-event-reminder.dto';
import { PatchPublicEventDto } from './dto/patch-public-event.dto';
import { EventsService } from './events.service';

@ApiTags('events')
@Controller('events')
@UseGuards(ThrottlerGuard)
export class EventsController {
  constructor(private readonly eventsService: EventsService) {}

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

  @Get(':id')
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Get event detail (approved public events plus caller’s own pending drafts)',
  })
  @ApiOkResponse({ description: 'Event payload (mobile-shaped JSON)' })
  findOne(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.eventsService.findOne(id, user);
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
