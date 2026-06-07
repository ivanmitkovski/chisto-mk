import { Injectable } from '@nestjs/common';
import { Report } from '../../prisma-client';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { AdminReportDetailDto, AdminReportListResponseDto } from '../dto/admin-report.dto';
import { AdminReportsQueueSummaryDto } from '../dto/admin-reports-queue-summary.dto';
import { ListReportsQueryDto } from '../dto/list-reports-query.dto';
import { AssignReportDto, AssignReportResponseDto } from '../dto/assign-report.dto';
import { UpdateReportStatusDto } from '../dto/update-report-status.dto';
import { ReportsModerationAssignService } from './reports-moderation-assign.service';
import { ReportsModerationDetailService } from './reports-moderation-detail.service';
import { ReportsModerationListService } from './reports-moderation-list.service';
import { ReportsModerationStatusService } from './reports-moderation-status.service';

@Injectable()
export class ReportsModerationService {
  constructor(
    private readonly list: ReportsModerationListService,
    private readonly status: ReportsModerationStatusService,
    private readonly detail: ReportsModerationDetailService,
    private readonly assign: ReportsModerationAssignService,
  ) {}

  findAllForModeration(query: ListReportsQueryDto): Promise<AdminReportListResponseDto> {
    return this.list.findAllForModeration(query);
  }

  getQueueSummary(): Promise<AdminReportsQueueSummaryDto> {
    return this.list.getQueueSummary();
  }

  updateStatus(
    reportId: string,
    dto: UpdateReportStatusDto,
    moderator: AuthenticatedUser,
  ): Promise<Report> {
    return this.status.updateStatus(reportId, dto, moderator);
  }

  findOneForModeration(reportId: string): Promise<AdminReportDetailDto> {
    return this.detail.findOneForModeration(reportId);
  }

  assignReport(
    reportId: string,
    dto: AssignReportDto,
    actor: AuthenticatedUser,
  ): Promise<AssignReportResponseDto> {
    return this.assign.assignReport(reportId, dto, actor);
  }
}
