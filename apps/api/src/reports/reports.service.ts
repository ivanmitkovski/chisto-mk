import { Injectable, NotFoundException } from '@nestjs/common';
import { Report } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ADMIN_PANEL_ROLES } from '../auth/admin-roles';
import { assertReportVisibleToUser } from '../common/helpers/assert-ownership.helper';
import { CreateReportWithLocationDto } from './dto/create-report-with-location.dto';
import { ReportSubmitResponseDto } from './dto/report-submit-response.dto';
import { AdminReportDetailDto, AdminReportListResponseDto } from './dto/admin-report.dto';
import {
  AdminDuplicateReportGroupDto,
  AdminDuplicateReportGroupsResponseDto,
  MergeDuplicateReportsDto,
  MergeDuplicateReportsResponseDto,
} from './dto/admin-duplicate-report.dto';
import { ListMyReportsQueryDto } from './dto/list-my-reports-query.dto';
import { ListReportsQueryDto } from './dto/list-reports-query.dto';
import { ReportCapacityDto } from './dto/report-capacity.dto';
import { ReportCapacityService } from './report-capacity.service';
import { UpdateReportStatusDto } from './dto/update-report-status.dto';
import { CitizenReportDetailDto } from './dto/citizen-report-detail.dto';
import { UserReportListItemDto } from './dto/user-report.dto';
import { ReportsModerationService } from './reports-moderation.service';
import { ReportsDuplicateMergeService } from './reports-duplicate-merge.service';
import type { ReportSubmitLocale } from './report-locale.util';
import { ReportSubmitService } from './report-submit.service';
import { ReportCitizenQueryService } from './report-citizen-query.service';

/**
 * Facade for report operations; delegates to specialized services (submit, citizen reads, moderation, merge).
 */
@Injectable()
export class ReportsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reportSubmit: ReportSubmitService,
    private readonly reportCitizenQuery: ReportCitizenQueryService,
    private readonly reportCapacity: ReportCapacityService,
    private readonly reportsModeration: ReportsModerationService,
    private readonly reportsDuplicateMerge: ReportsDuplicateMergeService,
  ) {}

  createWithLocation(
    user: AuthenticatedUser,
    dto: CreateReportWithLocationDto,
    headerIdempotencyKey?: string | string[],
    locale?: ReportSubmitLocale,
    requestId?: string,
  ): Promise<ReportSubmitResponseDto> {
    return this.reportSubmit.createWithLocation(user, dto, headerIdempotencyKey, locale, requestId);
  }

  appendMedia(reportId: string, userId: string, urls: string[]): Promise<void> {
    return this.reportSubmit.appendMedia(reportId, userId, urls);
  }

  findForCurrentUser(
    user: AuthenticatedUser,
    query: ListMyReportsQueryDto,
  ): Promise<{
    data: UserReportListItemDto[];
    total: number;
    page: number;
    limit: number;
  }> {
    return this.reportCitizenQuery.findForCurrentUser(user, query);
  }

  getCapacityForCurrentUser(user: AuthenticatedUser): Promise<ReportCapacityDto> {
    return this.reportCapacity.getCapacityForCurrentUser(user);
  }

  findAllForModeration(query: ListReportsQueryDto): Promise<AdminReportListResponseDto> {
    return this.reportsModeration.findAllForModeration(query);
  }

  findDuplicateGroups(query: ListReportsQueryDto): Promise<AdminDuplicateReportGroupsResponseDto> {
    return this.reportsDuplicateMerge.findDuplicateGroups(query);
  }

  findDuplicateGroupByReport(reportId: string): Promise<AdminDuplicateReportGroupDto> {
    return this.reportsDuplicateMerge.findDuplicateGroupByReport(reportId);
  }

  mergeDuplicateReports(
    reportId: string,
    dto: MergeDuplicateReportsDto,
    moderator: AuthenticatedUser,
  ): Promise<MergeDuplicateReportsResponseDto> {
    return this.reportsDuplicateMerge.mergeDuplicateReports(reportId, dto, moderator);
  }

  updateStatus(
    reportId: string,
    dto: UpdateReportStatusDto,
    moderator: AuthenticatedUser,
  ): Promise<Report> {
    return this.reportsModeration.updateStatus(reportId, dto, moderator);
  }

  findOneForModeration(reportId: string): Promise<AdminReportDetailDto> {
    return this.reportsModeration.findOneForModeration(reportId);
  }

  async findOne(
    reportId: string,
    user: AuthenticatedUser,
  ): Promise<AdminReportDetailDto | CitizenReportDetailDto> {
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
      select: {
        id: true,
        reporterId: true,
        coReporters: { select: { userId: true } },
      },
    });
    if (!report) {
      throw new NotFoundException({
        code: 'REPORT_NOT_FOUND',
        message: `Report with id '${reportId}' was not found`,
      });
    }
    const coReporterUserIds = report.coReporters.map((c) => c.userId);
    assertReportVisibleToUser(report, coReporterUserIds, user, ADMIN_PANEL_ROLES);
    if (ADMIN_PANEL_ROLES.includes(user.role)) {
      return this.findOneForModeration(reportId);
    }
    return this.reportCitizenQuery.findOneForCitizen(reportId, user);
  }

  findOneForCitizen(
    reportId: string,
    user: AuthenticatedUser,
  ): Promise<CitizenReportDetailDto> {
    return this.reportCitizenQuery.findOneForCitizen(reportId, user);
  }
}
