import { Injectable } from '@nestjs/common';
import { Report } from '../prisma-client';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { AdminReportDetailDto, AdminReportListResponseDto } from './dto/admin-report.dto';
import { ListReportsQueryDto } from './dto/list-reports-query.dto';
import { UpdateReportStatusDto } from './dto/update-report-status.dto';
import { ReportsModerationDetailService } from './reports-moderation-detail.service';
import { ReportsModerationListService } from './reports-moderation-list.service';
import { ReportsModerationStatusService } from './reports-moderation-status.service';

@Injectable()
export class ReportsModerationService {
  constructor(
    private readonly list: ReportsModerationListService,
    private readonly status: ReportsModerationStatusService,
    private readonly detail: ReportsModerationDetailService,
  ) {}

  findAllForModeration(query: ListReportsQueryDto): Promise<AdminReportListResponseDto> {
    return this.list.findAllForModeration(query);
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
}
