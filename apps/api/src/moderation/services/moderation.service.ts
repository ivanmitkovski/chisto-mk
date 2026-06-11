import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { AdminModerationCategory, Prisma } from '../../prisma-client';
import { AdminModerationNotifierService } from '../../admin-moderation-email/services/admin-moderation-notifier.service';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { AuditService } from '../../audit/services/audit.service';
import { ListAdminUgcReportsQueryDto } from '../dto/list-admin-ugc-reports-query.dto';
import { PatchAdminUgcReportDto } from '../dto/patch-admin-ugc-report.dto';
import { PostUgcReportDto } from '../dto/post-ugc-report.dto';
import { PostUserBlockDto } from '../dto/post-user-block.dto';
import { UgcSubjectVisibilityService } from './ugc-subject-visibility.service';

@Injectable()
export class ModerationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly subjectVisibility: UgcSubjectVisibilityService,
    private readonly moderationEmailNotifier: AdminModerationNotifierService,
    private readonly audit?: AuditService,
  ) {}

  async submitReport(user: AuthenticatedUser, dto: PostUgcReportDto) {
    const details = dto.details?.trim() || null;
    const report = await this.prisma.ugcContentReport.create({
      data: {
        reporterId: user.userId,
        subjectType: dto.subjectType,
        subjectId: dto.subjectId,
        reason: dto.reason,
        details,
      },
      select: { id: true, status: true, createdAt: true },
    });
    await this.prisma.adminNotification.create({
      data: {
        title: 'UGC report',
        message: `${dto.subjectType} reported (${dto.reason})`,
        timeLabel: 'now',
        tone: 'success',
        category: 'reports',
        href: `/dashboard/moderation/ugc?reportId=${report.id}`,
        messageTemplateKey: 'ugc.report.new',
        messageTemplateParams: {
          subjectType: dto.subjectType,
          subjectId: dto.subjectId,
          reason: dto.reason,
        },
      },
    });
    this.moderationEmailNotifier.notify({
      category: AdminModerationCategory.UGC_REPORT,
      resourceId: report.id,
      deepLinkPath: `/dashboard/moderation/ugc?reportId=${report.id}`,
      emailContext: {
        subjectType: dto.subjectType,
        reason: dto.reason,
        subjectId: dto.subjectId,
        detailsPreview: details,
        reporterEmail: user.email,
        reportedAt: report.createdAt.toISOString(),
      },
    });
    return report;
  }

  async listAdminUgcReports(query: ListAdminUgcReportsQueryDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 50;
    const skip = (page - 1) * limit;
    const where: Prisma.UgcContentReportWhereInput = {};
    if (query.status) where.status = query.status;
    if (query.subjectType) where.subjectType = query.subjectType;
    if (query.reporterId) where.reporterId = query.reporterId;
    const search = query.search?.trim();
    if (search) {
      where.OR = [
        { subjectId: { contains: search, mode: 'insensitive' } },
        { reason: { contains: search, mode: 'insensitive' } },
        { details: { contains: search, mode: 'insensitive' } },
        { reporter: { email: { contains: search, mode: 'insensitive' } } },
      ];
    }

    const [rows, total] = await this.prisma.$transaction([
      this.prisma.ugcContentReport.findMany({
        where,
        skip,
        take: limit,
        orderBy: [{ status: 'asc' }, { createdAt: 'desc' }],
        include: {
          reporter: {
            select: { id: true, firstName: true, lastName: true, email: true, role: true, status: true },
          },
        },
      }),
      this.prisma.ugcContentReport.count({ where }),
    ]);

    return {
      data: await Promise.all(rows.map((row) => this.toAdminUgcReport(row))),
      meta: { page, limit, total },
    };
  }

  async getAdminUgcReport(id: string) {
    const row = await this.prisma.ugcContentReport.findUnique({
      where: { id },
      include: {
        reporter: {
          select: { id: true, firstName: true, lastName: true, email: true, role: true, status: true },
        },
      },
    });
    if (!row) {
      throw new NotFoundException({
        code: 'UGC_REPORT_NOT_FOUND',
        message: 'UGC report not found',
      });
    }
    return this.toAdminUgcReport(row);
  }

  async patchAdminUgcReport(id: string, dto: PatchAdminUgcReportDto, actor: AuthenticatedUser) {
    const requiresPolicy =
      dto.action === 'hide_subject' ||
      dto.action === 'dismiss' ||
      dto.action === 'escalate' ||
      dto.action === 'restore_subject';
    const policyReason = dto.policyReason?.trim() || dto.note?.trim() || null;
    if (requiresPolicy && !policyReason) {
      throw new BadRequestException({
        code: 'POLICY_REASON_REQUIRED',
        message: 'A policy reason is required for this moderation action',
      });
    }

    const statusByAction: Record<PatchAdminUgcReportDto['action'], string> = {
      mark_reviewed: 'REVIEWED',
      dismiss: 'DISMISSED',
      escalate: 'ESCALATED',
      hide_subject: 'HIDDEN',
      restore_subject: 'REVIEWED',
    };
    const existing = await this.prisma.ugcContentReport.findUnique({
      where: { id },
      select: { id: true, status: true, subjectType: true, subjectId: true },
    });
    if (!existing) {
      throw new NotFoundException({
        code: 'UGC_REPORT_NOT_FOUND',
        message: 'UGC report not found',
      });
    }

    if (dto.action === 'hide_subject') {
      await this.subjectVisibility.applySubjectVisibility(existing.subjectType, existing.subjectId, true);
    } else if (dto.action === 'restore_subject') {
      await this.subjectVisibility.applySubjectVisibility(existing.subjectType, existing.subjectId, false);
    }

    const row = await this.prisma.ugcContentReport.update({
      where: { id },
      data: { status: statusByAction[dto.action] },
      include: {
        reporter: {
          select: { id: true, firstName: true, lastName: true, email: true, role: true, status: true },
        },
      },
    });
    await this.audit?.log({
      actorId: actor.userId,
      action: 'UGC_REPORT_MODERATED',
      resourceType: 'UgcContentReport',
      resourceId: id,
      metadata: {
        action: dto.action,
        note: dto.note?.trim() || null,
        policyReason,
        previousStatus: existing.status,
        nextStatus: row.status,
        subjectType: existing.subjectType,
        subjectId: existing.subjectId,
      },
    });
    return this.toAdminUgcReport(row);
  }

  async blockUser(user: AuthenticatedUser, dto: PostUserBlockDto) {
    if (dto.blockedUserId === user.userId) {
      throw new ConflictException({
        code: 'CANNOT_BLOCK_SELF',
        message: 'Cannot block yourself',
      });
    }
    return this.prisma.userBlock.upsert({
      where: {
        blockerId_blockedUserId: {
          blockerId: user.userId,
          blockedUserId: dto.blockedUserId,
        },
      },
      create: {
        blockerId: user.userId,
        blockedUserId: dto.blockedUserId,
      },
      update: {},
      select: { id: true, blockedUserId: true, createdAt: true },
    });
  }

  async listBlocks(user: AuthenticatedUser) {
    return this.prisma.userBlock.findMany({
      where: { blockerId: user.userId },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        blockedUserId: true,
        createdAt: true,
        blocked: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
          },
        },
      },
    });
  }

  async unblock(user: AuthenticatedUser, blockedUserId: string) {
    await this.prisma.userBlock.deleteMany({
      where: { blockerId: user.userId, blockedUserId },
    });
    return { ok: true };
  }

  /** User ids the caller has blocked (for UGC list filtering). */
  async blockedUserIdsFor(blockerId: string): Promise<string[]> {
    const rows = await this.prisma.userBlock.findMany({
      where: { blockerId },
      select: { blockedUserId: true },
    });
    return rows.map((r) => r.blockedUserId);
  }

  private caseStatusFromReportStatus(status: string): string {
    if (status === 'OPEN' || status === 'ESCALATED') return 'open';
    if (status === 'REVIEWED' || status === 'DISMISSED') return 'closed';
    if (status === 'HIDDEN') return 'closed';
    return 'in_review';
  }

  private async toAdminUgcReport(row: {
    id: string;
    reporterId: string;
    subjectType: string;
    subjectId: string;
    reason: string;
    details: string | null;
    status: string;
    createdAt: Date;
    updatedAt: Date;
    reporter: {
      id: string;
      firstName: string;
      lastName: string;
      email: string;
      role: string;
      status: string;
    };
  }) {
    const contentStatus = await this.subjectVisibility.resolveContentStatus(row.subjectType, row.subjectId);
    return {
      id: row.id,
      reporterId: row.reporterId,
      reporterName: `${row.reporter.firstName} ${row.reporter.lastName}`.trim(),
      reporterEmail: row.reporter.email,
      reporterRole: row.reporter.role,
      reporterStatus: row.reporter.status,
      subjectType: row.subjectType,
      subjectId: row.subjectId,
      reason: row.reason,
      details: row.details,
      status: row.status,
      caseStatus: this.caseStatusFromReportStatus(row.status),
      contentStatus,
      createdAt: row.createdAt.toISOString(),
      updatedAt: row.updatedAt.toISOString(),
    };
  }
}
