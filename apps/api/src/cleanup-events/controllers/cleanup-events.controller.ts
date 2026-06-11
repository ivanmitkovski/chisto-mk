import { Idempotent } from '../../common/idempotency/idempotency.decorator';
import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiConflictResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { ApiAdminCleanupEventsStandardErrors } from '../openapi/cleanup-events-openapi.decorators';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { ParseCuidPipe } from '../../common/pipes/parse-cuid.pipe';
import { Roles } from '../../auth/decorators/roles.decorator';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { PermissionsGuard } from '../../auth/guards/permissions.guard';
import { RequirePermission } from '../../auth/decorators/require-permission.decorator';
import { ADMIN_PANEL_ROLES, ADMIN_WRITE_ROLES } from '../../auth/constants/admin-roles';
import { ADMIN_PERMISSIONS } from '../../auth/constants/admin-permissions';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { EventAnalyticsResponseDto } from '../../events/dto/event-analytics-response.dto';
import { CleanupEventsService } from '../services/cleanup-events.service';
import { CleanupEventsCheckInRiskSignalsService } from '../services/cleanup-events-check-in-risk-signals.service';
import { CreateCleanupEventDto } from '../dto/create-cleanup-event.dto';
import { PatchCleanupEventDto } from '../dto/patch-cleanup-event.dto';
import { ListCleanupEventsQueryDto } from '../dto/list-cleanup-events-query.dto';
import { BulkModerateCleanupEventsDto } from '../dto/bulk-moderate-cleanup-events.dto';
import { ListCheckInRiskSignalsQueryDto } from '../dto/list-check-in-risk-signals-query.dto';
import { PatchCheckInRiskSignalDto } from '../dto/patch-check-in-risk-signal.dto';
import { CreateCleanupEventModerationNoteDto } from '../dto/create-cleanup-event-moderation-note.dto';
import { PaginationQueryDto } from '../../common/dto/pagination-query.dto';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';

@ApiTags('admin-cleanup-events')
@ApiStandardHttpErrorResponses()
@Controller('admin/cleanup-events')
export class CleanupEventsController {
  constructor(
    private readonly cleanupEventsService: CleanupEventsService,
    private readonly checkInRiskSignals: CleanupEventsCheckInRiskSignalsService,
  ) {}

  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard, ThrottlerGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List cleanup events' })
  @ApiOkResponse({ description: 'Cleanup events' })
  @ApiAdminCleanupEventsStandardErrors()
  list(@Query() query: ListCleanupEventsQueryDto) {
    return this.cleanupEventsService.list(query);
  }

  @Get('check-in-risk-signals')
  @UseGuards(JwtAuthGuard, RolesGuard, ThrottlerGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List check-in risk signals' })
  @ApiOkResponse({ description: 'Paginated risk signals' })
  @ApiAdminCleanupEventsStandardErrors()
  listCheckInRiskSignals(@Query() query: ListCheckInRiskSignalsQueryDto) {
    return this.checkInRiskSignals.listCheckInRiskSignals(query);
  }

  @Idempotent('cleanup-events_check_in_risk_signal_patch')
  @Patch('check-in-risk-signals/:id')
  @UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard, ThrottlerGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['events:write'])
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Resolve or dismiss a check-in risk signal' })
  @ApiOkResponse({ description: 'Updated risk signal' })
  @ApiAdminCleanupEventsStandardErrors()
  patchCheckInRiskSignal(
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: PatchCheckInRiskSignalDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.checkInRiskSignals.patchCheckInRiskSignal(id, dto, actor);
  }

  @Get(':id/participants')
  @UseGuards(JwtAuthGuard, RolesGuard, ThrottlerGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List participants who joined this cleanup event' })
  @ApiOkResponse({ description: 'Participant rows' })
  @ApiAdminCleanupEventsStandardErrors()
  listParticipants(@Param('id', ParseCuidPipe) id: string) {
    return this.cleanupEventsService.listParticipants(id);
  }

  @Idempotent('cleanup-events_participant_remove')
  @Delete(':id/participants/:userId')
  @UseGuards(JwtAuthGuard, RolesGuard, ThrottlerGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Remove a participant from a cleanup event' })
  @ApiOkResponse({ description: 'Updated cleanup event' })
  @ApiAdminCleanupEventsStandardErrors()
  removeParticipant(
    @Param('id', ParseCuidPipe) id: string,
    @Param('userId', ParseCuidPipe) userId: string,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.cleanupEventsService.removeParticipant(id, userId, actor);
  }

  @Get(':id/notes')
  @UseGuards(JwtAuthGuard, RolesGuard, ThrottlerGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List internal moderation notes for a cleanup event' })
  @ApiOkResponse({ description: 'Moderation notes' })
  @ApiAdminCleanupEventsStandardErrors()
  listNotes(@Param('id', ParseCuidPipe) id: string) {
    return this.cleanupEventsService.listNotes(id);
  }

  @Idempotent('cleanup-events_moderation_note_create')
  @Post(':id/notes')
  @UseGuards(JwtAuthGuard, RolesGuard, ThrottlerGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Add an internal moderation note' })
  @ApiOkResponse({ description: 'Created note' })
  @ApiAdminCleanupEventsStandardErrors()
  createNote(
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: CreateCleanupEventModerationNoteDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.cleanupEventsService.createNote(id, dto, actor);
  }

  @Idempotent('cleanup-events_moderation_note_delete')
  @Delete(':id/notes/:noteId')
  @UseGuards(JwtAuthGuard, RolesGuard, ThrottlerGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete an internal moderation note' })
  @ApiOkResponse({ description: 'Deletion result' })
  @ApiAdminCleanupEventsStandardErrors()
  deleteNote(
    @Param('id', ParseCuidPipe) id: string,
    @Param('noteId', ParseCuidPipe) noteId: string,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.cleanupEventsService.deleteNote(id, noteId, actor);
  }

  @Get(':id/audit')
  @UseGuards(JwtAuthGuard, RolesGuard, ThrottlerGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Audit trail for a cleanup event' })
  @ApiOkResponse({ description: 'Audit log entries' })
  @ApiAdminCleanupEventsStandardErrors()
  listAudit(@Param('id', ParseCuidPipe) id: string, @Query() pagination: PaginationQueryDto) {
    const p = pagination.page ?? 1;
    const l = pagination.limit ?? 50;
    return this.cleanupEventsService.listAuditTrail(id, { page: p, limit: l });
  }

  @Get(':id/analytics')
  @UseGuards(JwtAuthGuard, RolesGuard, ThrottlerGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Attendance analytics (admin read-only)' })
  @ApiOkResponse({ description: 'Analytics', type: EventAnalyticsResponseDto })
  @ApiAdminCleanupEventsStandardErrors()
  analytics(@Param('id', ParseCuidPipe) id: string) {
    return this.cleanupEventsService.getAnalytics(id);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard, RolesGuard, ThrottlerGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get cleanup event' })
  @ApiOkResponse({ description: 'Cleanup event' })
  @ApiAdminCleanupEventsStandardErrors()
  findOne(@Param('id', ParseCuidPipe) id: string) {
    return this.cleanupEventsService.findOne(id);
  }

  @Idempotent('cleanup-events_cleanup-events_108')
  @Post('bulk-moderate')
  @UseGuards(JwtAuthGuard, RolesGuard, ThrottlerGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Bulk approve or decline pending cleanup events',
    description:
      'Processes each id with the same rules as PATCH. `clientJobId` must be a new UUID per logical job; repeats return 409.',
  })
  @ApiConflictResponse({ description: 'Duplicate clientJobId for this actor' })
  @ApiOkResponse({ description: 'Per-event outcome summary' })
  @ApiAdminCleanupEventsStandardErrors()
  bulkModerate(@Body() dto: BulkModerateCleanupEventsDto, @CurrentUser() actor: AuthenticatedUser) {
    return this.cleanupEventsService.bulkModerate(dto, actor);
  }

  @Idempotent('cleanup-events_cleanup-events_125')
  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard, ThrottlerGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @Throttle({ default: { ttl: 60_000, limit: 30 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create cleanup event' })
  @ApiOkResponse({ description: 'Created' })
  @ApiAdminCleanupEventsStandardErrors()
  create(@Body() dto: CreateCleanupEventDto, @CurrentUser() actor: AuthenticatedUser) {
    return this.cleanupEventsService.create(dto, actor);
  }

  // safe-to-retry: repeated Patch is acceptable
  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard, ThrottlerGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @Throttle({ default: { ttl: 60_000, limit: 90 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update cleanup event' })
  @ApiOkResponse({ description: 'Updated' })
  @ApiAdminCleanupEventsStandardErrors()
  patch(
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: PatchCleanupEventDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.cleanupEventsService.patch(id, dto, actor);
  }
}
