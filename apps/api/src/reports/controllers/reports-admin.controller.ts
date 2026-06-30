import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { ADMIN_PANEL_ROLES } from '../../auth/constants/admin-roles';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { Roles } from '../../auth/decorators/roles.decorator';
import { AdminReportListResponseDto } from '../dto/admin-report.dto';
import { AdminReportsQueueSummaryDto } from '../dto/admin-reports-queue-summary.dto';
import {
  AdminDuplicateReportGroupDto,
  AdminDuplicateReportGroupsResponseDto,
  MergeDuplicateReportsDto,
  MergeDuplicateReportsResponseDto,
} from '../dto/admin-duplicate-report.dto';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { PermissionsGuard } from '../../auth/guards/permissions.guard';
import { RequirePermission } from '../../auth/decorators/require-permission.decorator';
import { ADMIN_PERMISSIONS } from '../../auth/constants/admin-permissions';
import { ListReportsQueryDto } from '../dto/list-reports-query.dto';
import { UpdateReportStatusDto } from '../dto/update-report-status.dto';
import { AssignReportDto, AssignReportResponseDto } from '../dto/assign-report.dto';
import {
  ReportViewerHeartbeatDto,
  ReportViewerPresenceResponseDto,
} from '../dto/report-viewer-presence.dto';
import { ReportsService } from '../services/reports.service';
import { ReportsDuplicateMergeService } from '../services/reports-duplicate-merge.service';
import { ReportViewerPresenceService } from '../services/report-viewer-presence.service';
import { ReportsUserThrottlerGuard } from '../guards/reports-user-throttler.guard';
import { ParseCuidPipe } from '../../common/pipes/parse-cuid.pipe';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';
import { Idempotent } from '../../common/idempotency/idempotency.decorator';

@ApiTags('reports')
@ApiStandardHttpErrorResponses()
@Controller('reports')
export class ReportsAdminController {
  constructor(
    private readonly reportsService: ReportsService,
    private readonly reportsDuplicateMerge: ReportsDuplicateMergeService,
    private readonly reportViewerPresenceService: ReportViewerPresenceService,
  ) {}

  @Get()
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @UseGuards(JwtAuthGuard, RolesGuard, ReportsUserThrottlerGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List reports for admin moderation queue' })
  @ApiOkResponse({ description: 'Reports fetched successfully', type: AdminReportListResponseDto })
  findAllForModeration(@Query() query: ListReportsQueryDto): Promise<AdminReportListResponseDto> {
    return this.reportsService.findAllForModeration(query);
  }

  @Get('queue-summary')
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @UseGuards(JwtAuthGuard, RolesGuard, ReportsUserThrottlerGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Global moderation queue counts for admin dashboard' })
  @ApiOkResponse({ description: 'Queue summary', type: AdminReportsQueueSummaryDto })
  getQueueSummary(): Promise<AdminReportsQueueSummaryDto> {
    return this.reportsService.getReportsQueueSummary();
  }

  @Get('duplicates')
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @UseGuards(JwtAuthGuard, RolesGuard, ReportsUserThrottlerGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List duplicate report groups for moderation' })
  @ApiOkResponse({
    description: 'Duplicate report groups fetched successfully',
    type: AdminDuplicateReportGroupsResponseDto,
  })
  findDuplicateGroups(@Query() query: ListReportsQueryDto): Promise<AdminDuplicateReportGroupsResponseDto> {
    return this.reportsDuplicateMerge.findDuplicateGroups(query);
  }

  @Get(':id/duplicates')
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @UseGuards(JwtAuthGuard, RolesGuard, ReportsUserThrottlerGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get duplicate group details for a report' })
  @ApiOkResponse({
    description: 'Duplicate report group fetched successfully',
    type: AdminDuplicateReportGroupDto,
  })
  findDuplicateGroupByReport(
    @Param('id', ParseCuidPipe) id: string,
  ): Promise<AdminDuplicateReportGroupDto> {
    return this.reportsDuplicateMerge.findDuplicateGroupByReport(id);
  }

  @Get(':id/viewers')
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard, ReportsUserThrottlerGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['reports:read'])
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List admins currently viewing a report' })
  @ApiOkResponse({ description: 'Active report viewers', type: ReportViewerPresenceResponseDto })
  async listReportViewers(
    @Param('id', ParseCuidPipe) id: string,
  ): Promise<ReportViewerPresenceResponseDto> {
    const viewers = await this.reportViewerPresenceService.list(id);
    return { viewers };
  }

  // safe-to-retry: repeated Post is acceptable
  @Post(':id/viewers/heartbeat')
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  @UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard, ReportsUserThrottlerGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['reports:read'])
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Register or refresh admin presence while viewing a report' })
  @ApiOkResponse({ description: 'Active report viewers after heartbeat', type: ReportViewerPresenceResponseDto })
  async heartbeatReportViewer(
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: ReportViewerHeartbeatDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<ReportViewerPresenceResponseDto> {
    const viewers = await this.reportViewerPresenceService.heartbeat(id, user, dto);
    return { viewers };
  }

  // safe-to-retry: repeated Delete is acceptable
  @Delete(':id/viewers/:sessionId')
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  @UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard, ReportsUserThrottlerGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['reports:read'])
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Remove admin presence when leaving a report view' })
  @ApiOkResponse({ description: 'Active report viewers after leave', type: ReportViewerPresenceResponseDto })
  async leaveReportViewer(
    @Param('id', ParseCuidPipe) id: string,
    @Param('sessionId') sessionId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<ReportViewerPresenceResponseDto> {
    const viewers = await this.reportViewerPresenceService.leave(id, sessionId, user.userId);
    return { viewers };
  }

  // safe-to-retry: repeated Patch is acceptable
  @Patch(':id/status')
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard, ReportsUserThrottlerGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['reports:moderate'])
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update report moderation status' })
  @ApiOkResponse({ description: 'Report status updated successfully' })
  updateStatus(
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: UpdateReportStatusDto,
    @CurrentUser() moderator: AuthenticatedUser,
  ) {
    return this.reportsService.updateStatus(id, dto, moderator);
  }

  // safe-to-retry: repeated Patch is acceptable
  @Patch(':id/assign')
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard, ReportsUserThrottlerGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['reports:moderate'])
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Assign or release a report for moderation review' })
  @ApiOkResponse({ description: 'Report assignment updated', type: AssignReportResponseDto })
  assignReport(
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: AssignReportDto,
    @CurrentUser() moderator: AuthenticatedUser,
  ): Promise<AssignReportResponseDto> {
    return this.reportsService.assignReport(id, dto, moderator);
  }

  @Idempotent('reports_reports_244')
  @Post(':id/merge')
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard, ReportsUserThrottlerGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @RequirePermission(ADMIN_PERMISSIONS['reports:merge'])
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Approve and merge child duplicate reports into a primary report' })
  @ApiOkResponse({
    description: 'Duplicate reports merged successfully',
    type: MergeDuplicateReportsResponseDto,
  })
  mergeDuplicates(
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: MergeDuplicateReportsDto,
    @CurrentUser() moderator: AuthenticatedUser,
  ): Promise<MergeDuplicateReportsResponseDto> {
    return this.reportsDuplicateMerge.mergeDuplicateReports(id, dto, moderator);
  }
}
