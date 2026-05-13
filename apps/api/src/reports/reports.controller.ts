import {
  Body,
  Controller,
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
import { ADMIN_PANEL_ROLES } from '../auth/admin-roles';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentAuthenticatedUser } from '../auth/current-authenticated-user.decorator';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { Roles } from '../auth/roles.decorator';
import { AdminReportDetailDto, AdminReportListResponseDto } from './dto/admin-report.dto';
import { CitizenReportDetailDto } from './dto/citizen-report-detail.dto';
import {
  AdminDuplicateReportGroupDto,
  AdminDuplicateReportGroupsResponseDto,
  MergeDuplicateReportsDto,
  MergeDuplicateReportsResponseDto,
} from './dto/admin-duplicate-report.dto';
import { RolesGuard } from '../auth/roles.guard';
import { CreateReportWithLocationDto } from './dto/create-report-with-location.dto';
import { ReportCapacityDto } from './dto/report-capacity.dto';
import { ReportMediaUrlsResponseDto } from './dto/report-media-urls-response.dto';
import { ReportSubmitResponseDto } from './dto/report-submit-response.dto';
import { ListMyReportsQueryDto } from './dto/list-my-reports-query.dto';
import { ListReportsQueryDto } from './dto/list-reports-query.dto';
import { UpdateReportStatusDto } from './dto/update-report-status.dto';
import { reportLocaleFromAcceptLanguage } from './report-locale.util';
import { ReportsService } from './reports.service';
import { ReportsUploadService } from './reports-upload.service';
import { NonEmptyUploadedFilesPipe } from './pipes/non-empty-uploaded-files.pipe';
import { ReportsUserThrottlerGuard } from './reports-user-throttler.guard';
import { ParseCuidPipe } from '../common/pipes/parse-cuid.pipe';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';

@ApiTags('reports')
@ApiStandardHttpErrorResponses()
@ApiExtraModels(AdminReportDetailDto, CitizenReportDetailDto)
@Controller('reports')
export class ReportsController {
  constructor(
    private readonly reportsService: ReportsService,
    private readonly reportsUploadService: ReportsUploadService,
  ) {}

  @Post()
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @UseGuards(JwtAuthGuard, ReportsUserThrottlerGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Create a report by location (finds or creates site; approval awards points later)',
  })
  @ApiCreatedResponse({
    description: 'Report created successfully',
    type: ReportSubmitResponseDto,
  })
  createWithLocation(
    @CurrentAuthenticatedUser() user: AuthenticatedUser,
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
    @CurrentAuthenticatedUser() user: AuthenticatedUser,
    @UploadedFiles(new NonEmptyUploadedFilesPipe()) files: Express.Multer.File[],
  ): Promise<ReportMediaUrlsResponseDto> {
    const urls = await this.reportsUploadService.uploadFiles(user.userId, files);
    return { urls };
  }

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
    @CurrentAuthenticatedUser() user: AuthenticatedUser,
    @UploadedFiles(new NonEmptyUploadedFilesPipe()) files: Express.Multer.File[],
  ): Promise<ReportMediaUrlsResponseDto> {
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
    @CurrentAuthenticatedUser() user: AuthenticatedUser,
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
    @CurrentAuthenticatedUser() user: AuthenticatedUser,
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
    return this.reportsService.findDuplicateGroups(query);
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
    return this.reportsService.findDuplicateGroupByReport(id);
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
    @CurrentAuthenticatedUser() user: AuthenticatedUser,
  ) {
    return this.reportsService.findOne(id, user);
  }

  @Patch(':id/status')
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @UseGuards(JwtAuthGuard, RolesGuard, ReportsUserThrottlerGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update report moderation status' })
  @ApiOkResponse({ description: 'Report status updated successfully' })
  updateStatus(
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: UpdateReportStatusDto,
    @CurrentAuthenticatedUser() moderator: AuthenticatedUser,
  ) {
    return this.reportsService.updateStatus(id, dto, moderator);
  }

  @Post(':id/merge')
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  @UseGuards(JwtAuthGuard, RolesGuard, ReportsUserThrottlerGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Approve and merge child duplicate reports into a primary report' })
  @ApiOkResponse({
    description: 'Duplicate reports merged successfully',
    type: MergeDuplicateReportsResponseDto,
  })
  mergeDuplicates(
    @Param('id', ParseCuidPipe) id: string,
    @Body() dto: MergeDuplicateReportsDto,
    @CurrentAuthenticatedUser() moderator: AuthenticatedUser,
  ): Promise<MergeDuplicateReportsResponseDto> {
    return this.reportsService.mergeDuplicateReports(id, dto, moderator);
  }
}
