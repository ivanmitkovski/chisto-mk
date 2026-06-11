import {
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
  UseInterceptors,
  UploadedFiles,
} from '@nestjs/common';
import type { Request } from 'express';
import { Throttle } from '@nestjs/throttler';
import { Idempotent } from '../../common/idempotency/idempotency.decorator';
import { FilesInterceptor } from '@nestjs/platform-express';
import * as multer from 'multer';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiExtraModels,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  getSchemaPath,
} from '@nestjs/swagger';
import { ADMIN_PANEL_ROLES } from '../../auth/constants/admin-roles';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { PhoneVerifiedGuard } from '../../auth/guards/phone-verified.guard';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { Roles } from '../../auth/decorators/roles.decorator';
import { AdminReportDetailDto, AdminReportListResponseDto } from '../dto/admin-report.dto';
import { AdminReportsQueueSummaryDto } from '../dto/admin-reports-queue-summary.dto';
import { CitizenReportDetailDto } from '../dto/citizen-report-detail.dto';
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
import { CreateReportWithLocationDto } from '../dto/create-report-with-location.dto';
import { ReportCapacityDto } from '../dto/report-capacity.dto';
import { ReportMediaUrlsResponseDto } from '../dto/report-media-urls-response.dto';
import { ReportSubmitResponseDto } from '../dto/report-submit-response.dto';
import { ListMyReportsQueryDto } from '../dto/list-my-reports-query.dto';
import { ListReportsQueryDto } from '../dto/list-reports-query.dto';
import { UpdateReportStatusDto } from '../dto/update-report-status.dto';
import { AssignReportDto, AssignReportResponseDto } from '../dto/assign-report.dto';
import {
  ReportViewerHeartbeatDto,
  ReportViewerPresenceResponseDto,
} from '../dto/report-viewer-presence.dto';
import { reportLocaleFromAcceptLanguage } from '../util/report-locale.util';
import { ReportsService } from '../services/reports.service';
import { ReportsDuplicateMergeService } from '../services/reports-duplicate-merge.service';
import { ReportViewerPresenceService } from '../services/report-viewer-presence.service';
import { ReportsUploadService } from '../services/reports-upload.service';
import { ReportSubmitMediaAppendService } from '../services/report-submit-media-append.service';
import { NonEmptyUploadedFilesPipe } from '../pipes/non-empty-uploaded-files.pipe';
import { ReportsUserThrottlerGuard } from '../guards/reports-user-throttler.guard';
import { ParseCuidPipe } from '../../common/pipes/parse-cuid.pipe';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';

@ApiTags('reports')
@ApiStandardHttpErrorResponses()
@ApiExtraModels(AdminReportDetailDto, CitizenReportDetailDto)
@Controller('reports')
export class ReportsController {
  constructor(
    private readonly reportsService: ReportsService,
    private readonly reportsDuplicateMerge: ReportsDuplicateMergeService,
    private readonly reportsUploadService: ReportsUploadService,
    private readonly reportMediaAppend: ReportSubmitMediaAppendService,
    private readonly reportViewerPresenceService: ReportViewerPresenceService,
  ) {}

  @Idempotent('reports_reports_68')
  @Post()
  @Idempotent('report_create')
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @UseGuards(JwtAuthGuard, PhoneVerifiedGuard, ReportsUserThrottlerGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Create a report by location (finds or creates site; approval awards points later)',
  })
  @ApiCreatedResponse({
    description: 'Report created successfully',
    type: ReportSubmitResponseDto,
  })
  createWithLocation(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateReportWithLocationDto,
    @Req() req: Request & { requestId?: string },
    @Headers('idempotency-key') idempotencyKey?: string | string[],
    @Headers('accept-language') acceptLanguage?: string | string[],
  ): Promise<ReportSubmitResponseDto> {
    return this.reportsService.createWithLocation(
      user,
      dto,
      idempotencyKey,
      reportLocaleFromAcceptLanguage(acceptLanguage),
      req.requestId,
    );
  }

  @Idempotent('reports_reports_96')
  @Post('upload')
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  @UseGuards(JwtAuthGuard, ReportsUserThrottlerGuard)
  @ApiBearerAuth()
  @UseInterceptors(
    FilesInterceptor('files', 5, {
      storage: multer.memoryStorage(),
      limits: { fileSize: 10 * 1024 * 1024 },
    }),
  )
  @ApiOperation({ summary: 'Upload report photos (max 5, jpeg/png/webp, 10MB each)' })
  @ApiOkResponse({ description: 'Uploaded file URLs', type: ReportMediaUrlsResponseDto })
  async upload(
    @CurrentUser() user: AuthenticatedUser,
    @UploadedFiles(new NonEmptyUploadedFilesPipe()) files: Express.Multer.File[],
  ): Promise<ReportMediaUrlsResponseDto> {
    const urls = await this.reportsUploadService.uploadFiles(user.userId, files);
    return { urls };
  }

  @Idempotent('reports_reports_116')
  @Post(':id/media')
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  @UseGuards(JwtAuthGuard, ReportsUserThrottlerGuard)
  @ApiBearerAuth()
  @UseInterceptors(
    FilesInterceptor('files', 5, {
      storage: multer.memoryStorage(),
      limits: { fileSize: 10 * 1024 * 1024 },
    }),
  )
  @ApiOperation({
    summary: 'Append photos to an existing report (reporter or co-reporter only)',
  })
  @ApiOkResponse({ description: 'Media appended successfully', type: ReportMediaUrlsResponseDto })
  async appendMedia(
    @Param('id', ParseCuidPipe) reportId: string,
    @CurrentUser() user: AuthenticatedUser,
    @UploadedFiles(new NonEmptyUploadedFilesPipe()) files: Express.Multer.File[],
  ): Promise<ReportMediaUrlsResponseDto> {
    await this.reportMediaAppend.assertCanAppendMedia(reportId, user.userId);
    const urls = await this.reportsUploadService.uploadFiles(user.userId, files);
    await this.reportsService.appendMedia(reportId, user.userId, urls);
    return { urls };
  }

  @Get('me')
  @UseGuards(JwtAuthGuard, ReportsUserThrottlerGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List reports created by the authenticated user (paginated)' })
  @ApiOkResponse({
    description: 'Reports for the current user fetched successfully',
  })
  findForCurrentUser(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: ListMyReportsQueryDto,
  ) {
    return this.reportsService.findForCurrentUser(user, query);
  }

  @Get('capacity')
  @UseGuards(JwtAuthGuard, ReportsUserThrottlerGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current reporting capacity and emergency allowance status' })
  @ApiOkResponse({ description: 'Reporting capacity fetched successfully', type: ReportCapacityDto })
  getCapacityForCurrentUser(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<ReportCapacityDto> {
    return this.reportsService.getCapacityForCurrentUser(user);
  }

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

  // SECURITY: Authorization (moderator vs owner vs co-reporter) is enforced in ReportsService.findOne — never trust the client alone.
  @Get(':id')
  @UseGuards(JwtAuthGuard, ReportsUserThrottlerGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Get report details (admin: full moderation view, citizen: own reports only)',
  })
  @ApiOkResponse({
    description: 'Report fetched successfully (shape depends on moderator vs citizen access)',
    schema: {
      oneOf: [
        { $ref: getSchemaPath(AdminReportDetailDto) },
        { $ref: getSchemaPath(CitizenReportDetailDto) },
      ],
    },
  })
  findOne(
    @Param('id', ParseCuidPipe) id: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.reportsService.findOne(id, user);
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
