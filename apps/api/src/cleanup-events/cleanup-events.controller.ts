import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiConflictResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ADMIN_PANEL_ROLES, ADMIN_WRITE_ROLES } from '../auth/admin-roles';
import { EventAnalyticsResponseDto } from '../events/dto/event-analytics-response.dto';
import { CleanupEventsService } from './cleanup-events.service';
import { CreateCleanupEventDto } from './dto/create-cleanup-event.dto';
import { PatchCleanupEventDto } from './dto/patch-cleanup-event.dto';
import { ListCleanupEventsQueryDto } from './dto/list-cleanup-events-query.dto';
import { BulkModerateCleanupEventsDto } from './dto/bulk-moderate-cleanup-events.dto';
import { ListCheckInRiskSignalsQueryDto } from './dto/list-check-in-risk-signals-query.dto';

@ApiTags('admin-cleanup-events')
@Controller('admin/cleanup-events')
export class CleanupEventsController {
  constructor(private readonly cleanupEventsService: CleanupEventsService) {}

  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard, ThrottlerGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @Throttle({ default: { ttl: 60_000, limit: 120 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List cleanup events' })
  @ApiOkResponse({ description: 'Cleanup events' })
  list(@Query() query: ListCleanupEventsQueryDto) {
    return this.cleanupEventsService.list(query);
  }

  @Get('check-in-risk-signals')
  @UseGuards(JwtAuthGuard, RolesGuard, ThrottlerGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @Throttle({ default: { ttl: 60_000, limit: 60 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List active check-in risk signals (non-expired)' })
  @ApiOkResponse({ description: 'Paginated risk signals' })
  listCheckInRiskSignals(@Query() query: ListCheckInRiskSignalsQueryDto) {
    return this.cleanupEventsService.listCheckInRiskSignals(query);
  }

  @Get(':id/audit')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Audit trail for a cleanup event' })
  @ApiOkResponse({ description: 'Audit log entries' })
  listAudit(
    @Param('id') id: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const p = page != null && page !== '' ? Math.max(1, parseInt(page, 10) || 1) : 1;
    const l =
      limit != null && limit !== ''
        ? Math.min(100, Math.max(1, parseInt(limit, 10) || 50))
        : 50;
    return this.cleanupEventsService.listAuditTrail(id, { page: p, limit: l });
  }

  @Get(':id/analytics')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Attendance analytics (admin read-only)' })
  @ApiOkResponse({ description: 'Analytics', type: EventAnalyticsResponseDto })
  analytics(@Param('id') id: string) {
    return this.cleanupEventsService.getAnalytics(id);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get cleanup event' })
  @ApiOkResponse({ description: 'Cleanup event' })
  findOne(@Param('id') id: string) {
    return this.cleanupEventsService.findOne(id);
  }

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
  bulkModerate(@Body() dto: BulkModerateCleanupEventsDto, @CurrentUser() actor: AuthenticatedUser) {
    return this.cleanupEventsService.bulkModerate(dto, actor);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard, ThrottlerGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @Throttle({ default: { ttl: 60_000, limit: 30 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create cleanup event' })
  @ApiOkResponse({ description: 'Created' })
  create(@Body() dto: CreateCleanupEventDto, @CurrentUser() actor: AuthenticatedUser) {
    return this.cleanupEventsService.create(dto, actor);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard, ThrottlerGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @Throttle({ default: { ttl: 60_000, limit: 90 } })
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update cleanup event' })
  @ApiOkResponse({ description: 'Updated' })
  patch(
    @Param('id') id: string,
    @Body() dto: PatchCleanupEventDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.cleanupEventsService.patch(id, dto, actor);
  }
}
