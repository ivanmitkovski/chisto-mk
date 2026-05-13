import { Injectable } from '@nestjs/common';
import {
  AdminDuplicateReportGroupDto,
  AdminDuplicateReportGroupsResponseDto,
  MergeDuplicateReportsDto,
  MergeDuplicateReportsResponseDto,
} from './dto/admin-duplicate-report.dto';
import { ListReportsQueryDto } from './dto/list-reports-query.dto';
import { DuplicateGroupQueryService } from './duplicates/duplicate-group-query.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { DuplicateMergeTransactionService } from './duplicate-merge-transaction.service';

@Injectable()
export class ReportsDuplicateMergeService {
  constructor(
    private readonly duplicateGroupQuery: DuplicateGroupQueryService,
    private readonly mergeTransaction: DuplicateMergeTransactionService,
  ) {}

  findDuplicateGroups(query: ListReportsQueryDto): Promise<AdminDuplicateReportGroupsResponseDto> {
    return this.duplicateGroupQuery.findDuplicateGroups(query);
  }

  findDuplicateGroupByReport(reportId: string): Promise<AdminDuplicateReportGroupDto> {
    return this.duplicateGroupQuery.findDuplicateGroupByReport(reportId);
  }

  mergeDuplicateReports(
    reportId: string,
    dto: MergeDuplicateReportsDto,
    moderator: AuthenticatedUser,
  ): Promise<MergeDuplicateReportsResponseDto> {
    return this.mergeTransaction.mergeDuplicateReports(reportId, dto, moderator);
  }
}
