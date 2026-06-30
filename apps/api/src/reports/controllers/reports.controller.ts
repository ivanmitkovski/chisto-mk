import {
  Body,
  Controller,
  Get,
  Headers,
  Param,
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
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { PhoneVerifiedGuard } from '../../auth/guards/phone-verified.guard';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { AdminReportDetailDto } from '../dto/admin-report.dto';
import { CitizenReportDetailDto } from '../dto/citizen-report-detail.dto';
import { CreateReportWithLocationDto } from '../dto/create-report-with-location.dto';
import { ReportCapacityDto } from '../dto/report-capacity.dto';
import { ReportMediaUrlsResponseDto } from '../dto/report-media-urls-response.dto';
import { ReportSubmitResponseDto } from '../dto/report-submit-response.dto';
import { ListMyReportsQueryDto } from '../dto/list-my-reports-query.dto';
import { reportLocaleFromAcceptLanguage } from '../util/report-locale.util';
import { ReportsService } from '../services/reports.service';
import { ReportsUploadService } from '../services/reports-upload.service';
import { ReportSubmitMediaAppendService } from '../services/report-submit-media-append.service';
import { NonEmptyUploadedFilesPipe } from '../pipes/non-empty-uploaded-files.pipe';
import {
  CITIZEN_IMAGE_UPLOAD_MAX_BYTES,
  CITIZEN_IMAGE_UPLOAD_MAX_FILES,
} from '../../storage/constants/citizen-media-upload.constants';
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
    private readonly reportsUploadService: ReportsUploadService,
    private readonly reportMediaAppend: ReportSubmitMediaAppendService,
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
    FilesInterceptor('files', CITIZEN_IMAGE_UPLOAD_MAX_FILES, {
      storage: multer.memoryStorage(),
      limits: { fileSize: CITIZEN_IMAGE_UPLOAD_MAX_BYTES },
    }),
  )
  @ApiOperation({ summary: 'Upload report photos (max 5, jpeg/png/webp, 12MB each)' })
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
    FilesInterceptor('files', CITIZEN_IMAGE_UPLOAD_MAX_FILES, {
      storage: multer.memoryStorage(),
      limits: { fileSize: CITIZEN_IMAGE_UPLOAD_MAX_BYTES },
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
}
