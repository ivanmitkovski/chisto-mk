import { Body, Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { CheckEventConflictQueryDto } from './dto/check-event-conflict-query.dto';
import { CreatePublicEventDto } from './dto/create-public-event.dto';
import { EventSearchDto } from './dto/event-search.dto';
import { ListEventsQueryDto } from './dto/list-events-query.dto';
import { FieldBatchDto, FieldBatchResultDto } from './dto/field-batch.dto';
import {
  EventSearchResponseDto,
  EventsListResponseDto,
  ScheduleConflictPreviewResponseDto,
} from './dto/events-openapi-responses.dto';
import { EventMobileResponseDto } from './dto/event-mobile-response.dto';
import { EventsFieldBatchService } from './events-field-batch.service';
import { EventsCreationService } from './events-creation.service';
import { EventsQueryService } from './events-query.service';
import { EventsScheduleConflictPreviewQueryService } from './events-schedule-conflict-preview-query.service';
import { EventsSearchService } from './events-search.service';
import { ApiEventsJwtStandardErrors } from './events-openapi.decorators';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';

@ApiTags('events')
@ApiStandardHttpErrorResponses()
@Controller('events')
@UseGuards(ThrottlerGuard)
export class EventsListController {
  constructor(
    private readonly query: EventsQueryService,
    private readonly creation: EventsCreationService,
    private readonly eventSearch: EventsSearchService,
    private readonly schedulePreview: EventsScheduleConflictPreviewQueryService,
    private readonly fieldBatchService: EventsFieldBatchService,
  ) {}

  @Get()
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'List cleanup events (approved public events plus caller’s own pending drafts)',
  })
  @ApiOkResponse({ description: 'Paginated events', type: EventsListResponseDto })
  @ApiEventsJwtStandardErrors()
  list(@CurrentUser() user: AuthenticatedUser, @Query() query: ListEventsQueryDto) {
    return this.query.list(user, query);
  }

  @Post('search')
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Ranked full-text search for cleanup events (with ILIKE fallback)' })
  @ApiOkResponse({ description: 'Search hits + suggestions', type: EventSearchResponseDto })
  @ApiEventsJwtStandardErrors()
  search(@CurrentUser() user: AuthenticatedUser, @Body() dto: EventSearchDto) {
    return this.eventSearch.search(user, dto);
  }

  @Get('check-conflict')
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Preview duplicate schedule at a site (buffered overlap; excludes cancelled/completed)',
  })
  @ApiOkResponse({
    description: 'Schedule overlap preview',
    type: ScheduleConflictPreviewResponseDto,
  })
  @ApiEventsJwtStandardErrors()
  checkConflict(
    @CurrentUser() _user: AuthenticatedUser,
    @Query() query: CheckEventConflictQueryDto,
  ) {
    return this.schedulePreview.checkScheduleConflictPreview(query);
  }

  @Post('field-batch')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 30 } })
  @ApiOperation({ summary: 'Apply queued field-mode operations (offline sync)' })
  @ApiOkResponse({ description: 'Batch outcome', type: FieldBatchResultDto })
  @ApiEventsJwtStandardErrors()
  applyFieldBatch(@CurrentUser() user: AuthenticatedUser, @Body() dto: FieldBatchDto) {
    return this.fieldBatchService.applyBatch(user, dto);
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Throttle({ default: { ttl: 60_000, limit: 20 } })
  @ApiOperation({ summary: 'Create cleanup event (PENDING for citizens, APPROVED for staff)' })
  @ApiOkResponse({ description: 'Created event', type: EventMobileResponseDto })
  @ApiEventsJwtStandardErrors({ include409: true })
  create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreatePublicEventDto) {
    return this.creation.create(dto, user);
  }
}
