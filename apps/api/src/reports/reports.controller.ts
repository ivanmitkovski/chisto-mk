import {
  Body,
  Controller,
  Get,
  MessageEvent as NestMessageEvent,
  Param,
  Patch,
  Post,
  Query,
  Sse,
  UnauthorizedException,
  UseGuards,
  UseInterceptors,
  UploadedFiles,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import * as multer from 'multer';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { ADMIN_PANEL_ROLES } from '../auth/admin-roles';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { Roles } from '../auth/roles.decorator';
import { AdminReportListResponseDto } from './dto/admin-report.dto';
import { Observable, interval, map, merge } from 'rxjs';
import {
  AdminDuplicateReportGroupDto,
  AdminDuplicateReportGroupsResponseDto,
  MergeDuplicateReportsDto,
  MergeDuplicateReportsResponseDto,
} from './dto/admin-duplicate-report.dto';
import { RolesGuard } from '../auth/roles.guard';
import { CreateReportWithLocationDto } from './dto/create-report-with-location.dto';
import { ReportCapacityDto } from './dto/report-capacity.dto';
import { ReportSubmitResponseDto } from './dto/report-submit-response.dto';
import { ListMyReportsQueryDto } from './dto/list-my-reports-query.dto';
import { ListReportsQueryDto } from './dto/list-reports-query.dto';
import { UpdateReportStatusDto } from './dto/update-report-status.dto';
import { ReportsService } from './reports.service';
import { ReportsUploadService } from './reports-upload.service';
import { ReportsOwnerEventsService } from './reports-owner-events.service';

@ApiTags('reports')
@Controller('reports')
export class ReportsController {
  constructor(
    private readonly reportsService: ReportsService,
    private readonly reportsUploadService: ReportsUploadService,
    private readonly reportsOwnerEventsService: ReportsOwnerEventsService,
  ) {}

  private static readonly HEARTBEAT_INTERVAL_MS = 30_000;

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a report by location (finds or creates site, awards points)' })
  @ApiCreatedResponse({
    description: 'Report created successfully',
    type: ReportSubmitResponseDto,
  })
  createWithLocation(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @Body() dto: CreateReportWithLocationDto,
  ): Promise<ReportSubmitResponseDto> {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }
    return this.reportsService.createWithLocation(user, dto);
  }

  @Post('upload')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @UseInterceptors(
    FilesInterceptor('files', 5, {
      storage: multer.memoryStorage(),
      limits: { fileSize: 10 * 1024 * 1024 },
    }),
  )
  @ApiOperation({ summary: 'Upload report photos (max 5, jpeg/png/webp, 10MB each)' })
  @ApiOkResponse({ description: 'Uploaded file URLs' })
  async upload(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @UploadedFiles() files: Express.Multer.File[],
  ): Promise<{ urls: string[] }> {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }
    const urls = await this.reportsUploadService.uploadFiles(
      user.userId,
      files || [],
    );
    return { urls };
  }

  @Post(':id/media')
  @UseGuards(JwtAuthGuard)
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
  @ApiOkResponse({ description: 'Media appended successfully' })
  async appendMedia(
    @Param('id') reportId: string,
    @CurrentUser() user: AuthenticatedUser | undefined,
    @UploadedFiles() files: Express.Multer.File[],
  ): Promise<{ urls: string[] }> {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }
    const urls = await this.reportsUploadService.uploadFiles(
      user.userId,
      files || [],
    );
    await this.reportsService.appendMedia(reportId, user.userId, urls);
    return { urls };
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
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
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current reporting capacity and emergency allowance status' })
  @ApiOkResponse({ description: 'Reporting capacity fetched successfully', type: ReportCapacityDto })
  getCapacityForCurrentUser(
    @CurrentUser() user: AuthenticatedUser | undefined,
  ): Promise<ReportCapacityDto> {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }
    return this.reportsService.getCapacityForCurrentUser(user);
  }

  @Get('events')
  @Sse()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Server-Sent Events stream for real-time updates to your reports' })
  streamMyReportEvents(
    @CurrentUser() user: AuthenticatedUser | undefined,
  ): Observable<NestMessageEvent> {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }

    const ownerEvents = this.reportsOwnerEventsService.getEventsForOwner(user.userId).pipe(
      map((event) => ({
        data: event as object,
        type: event.type,
        id: event.eventId,
      })),
    );

    const heartbeat = interval(ReportsController.HEARTBEAT_INTERVAL_MS).pipe(
      map(() => ({ data: { type: 'heartbeat' } } as NestMessageEvent)),
    );

    return merge(ownerEvents, heartbeat);
  }

  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List reports for admin moderation queue' })
  @ApiOkResponse({ description: 'Reports fetched successfully', type: AdminReportListResponseDto })
  findAllForModeration(@Query() query: ListReportsQueryDto): Promise<AdminReportListResponseDto> {
    return this.reportsService.findAllForModeration(query);
  }

  @Get('duplicates')
  @UseGuards(JwtAuthGuard, RolesGuard)
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
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get duplicate group details for a report' })
  @ApiOkResponse({
    description: 'Duplicate report group fetched successfully',
    type: AdminDuplicateReportGroupDto,
  })
  findDuplicateGroupByReport(@Param('id') id: string): Promise<AdminDuplicateReportGroupDto> {
    return this.reportsService.findDuplicateGroupByReport(id);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Get report details (admin: full moderation view, citizen: own reports only)',
  })
  @ApiOkResponse({ description: 'Report fetched successfully' })
  findOne(
    @Param('id') id: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }
    return this.reportsService.findOne(id, user);
  }

  @Patch(':id/status')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update report moderation status' })
  @ApiOkResponse({ description: 'Report status updated successfully' })
  updateStatus(
    @Param('id') id: string,
    @Body() dto: UpdateReportStatusDto,
    @CurrentUser() moderator: AuthenticatedUser,
  ) {
    return this.reportsService.updateStatus(id, dto, moderator);
  }

  @Post(':id/merge')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Approve and merge child duplicate reports into a primary report' })
  @ApiOkResponse({
    description: 'Duplicate reports merged successfully',
    type: MergeDuplicateReportsResponseDto,
  })
  mergeDuplicates(
    @Param('id') id: string,
    @Body() dto: MergeDuplicateReportsDto,
    @CurrentUser() moderator: AuthenticatedUser,
  ): Promise<MergeDuplicateReportsResponseDto> {
    return this.reportsService.mergeDuplicateReports(id, dto, moderator);
  }
}
