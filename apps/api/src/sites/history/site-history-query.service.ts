import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, SiteHistoryEntryKind, SiteStatus } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ADMIN_PANEL_ROLES } from '../../auth/admin-roles';
import {
  SiteHistoryEntryDto,
  SiteHistoryListResponseDto,
  SiteHistorySummaryDto,
} from './dto/site-history-entry.dto';

const DEFAULT_LIMIT = 30;
const MAX_LIMIT = 100;

/** Kinds hidden from non-reporters (moderation privacy). */
const REPORTER_ONLY_KINDS: SiteHistoryEntryKind[] = [
  SiteHistoryEntryKind.REPORT_REJECTED,
];

@Injectable()
export class SiteHistoryQueryService {
  constructor(private readonly prisma: PrismaService) {}

  private isAdmin(user?: AuthenticatedUser): boolean {
    if (!user) return false;
    return ADMIN_PANEL_ROLES.includes(user.role);
  }

  async list(
    siteId: string,
    query: { limit?: number; beforeId?: string },
    user?: AuthenticatedUser,
  ): Promise<SiteHistoryListResponseDto> {
    const site = await this.prisma.site.findUnique({
      where: { id: siteId },
      select: { id: true, createdAt: true, status: true },
    });
    if (!site) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: `Site with id '${siteId}' was not found`,
      });
    }

    const limit = Math.min(Math.max(query.limit ?? DEFAULT_LIMIT, 1), MAX_LIMIT);
    const beforeId = query.beforeId?.trim() || null;

    let cursorOccurredAt: Date | undefined;
    if (beforeId) {
      const cursor = await this.prisma.siteHistoryEntry.findFirst({
        where: { id: beforeId, siteId },
        select: { occurredAt: true },
      });
      if (!cursor) {
        return { items: [], nextBeforeId: null, summary: null };
      }
      cursorOccurredAt = cursor.occurredAt;
    }

    const where: Prisma.SiteHistoryEntryWhereInput = { siteId };
    if (cursorOccurredAt) {
      where.occurredAt = { lt: cursorOccurredAt };
    }

    const rows = await this.prisma.siteHistoryEntry.findMany({
      where,
      orderBy: [{ occurredAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      include: {
        site: false,
      },
    });

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;

    const actorIds = [
      ...new Set(page.map((r) => r.actorUserId).filter((id): id is string => id != null)),
    ];
    const actors =
      actorIds.length > 0
        ? await this.prisma.user.findMany({
            where: { id: { in: actorIds } },
            select: { id: true, firstName: true, lastName: true, role: true },
          })
        : [];
    const actorById = new Map(actors.map((a) => [a.id, a]));

    const viewerIsAdmin = this.isAdmin(user);
    let reporterReportIds: Set<string> | null = null;
    if (user && !viewerIsAdmin) {
      const reporterReports = await this.prisma.report.findMany({
        where: {
          siteId,
          OR: [{ reporterId: user.userId }, { coReporters: { some: { userId: user.userId } } }],
        },
        select: { id: true },
      });
      reporterReportIds = new Set(reporterReports.map((r) => r.id));
    }

    const items: SiteHistoryEntryDto[] = [];
    for (const row of page) {
      if (
        !viewerIsAdmin &&
        REPORTER_ONLY_KINDS.includes(row.kind) &&
        row.reportId != null &&
        reporterReportIds != null &&
        !reporterReportIds.has(row.reportId)
      ) {
        continue;
      }

      const actorRow = row.actorUserId ? actorById.get(row.actorUserId) : undefined;
      items.push({
        id: row.id,
        kind: row.kind,
        occurredAt: row.occurredAt.toISOString(),
        fromStatus: row.fromStatus,
        toStatus: row.toStatus,
        reportId: row.reportId,
        cleanupEventId: row.cleanupEventId,
        actor:
          row.actorUserId == null
            ? null
            : {
                id: row.actorUserId,
                displayName: actorRow
                  ? `${actorRow.firstName} ${actorRow.lastName}`.trim() || null
                  : null,
                role: row.actorRole ?? actorRow?.role ?? null,
              },
        note: row.note,
        metadata:
          row.metadata != null && typeof row.metadata === 'object' && !Array.isArray(row.metadata)
            ? (row.metadata as Record<string, unknown>)
            : null,
      });
    }

    if (items.length === 0 && !beforeId) {
      items.push({
        id: `bootstrap-site-created-${site.id}`,
        kind: SiteHistoryEntryKind.SITE_CREATED,
        occurredAt: site.createdAt.toISOString(),
        fromStatus: null,
        toStatus: site.status,
        reportId: null,
        cleanupEventId: null,
        actor: null,
        note: null,
        metadata: { synthetic: true },
      });
    }

    const nextBeforeId = hasMore ? page[page.length - 1]!.id : null;
    const summary =
      beforeId == null ? await this.buildSummary(siteId, site) : null;
    return { items, nextBeforeId, summary };
  }

  private async buildSummary(
    siteId: string,
    site: { createdAt: Date; status: SiteStatus },
  ): Promise<SiteHistorySummaryDto> {
    const [totalEntries, kindGroups, oldestEntry, newestEntry] = await Promise.all([
      this.prisma.siteHistoryEntry.count({ where: { siteId } }),
      this.prisma.siteHistoryEntry.groupBy({
        by: ['kind'],
        where: { siteId },
        _count: { kind: true },
      }),
      this.prisma.siteHistoryEntry.findFirst({
        where: { siteId },
        orderBy: [{ occurredAt: 'asc' }, { id: 'asc' }],
        select: { occurredAt: true },
      }),
      this.prisma.siteHistoryEntry.findFirst({
        where: { siteId },
        orderBy: [{ occurredAt: 'desc' }, { id: 'desc' }],
        select: { occurredAt: true },
      }),
    ]);

    const countForKind = (kind: SiteHistoryEntryKind): number =>
      kindGroups.find((g) => g.kind === kind)?._count.kind ?? 0;

    const firstActivityAt = oldestEntry?.occurredAt ?? site.createdAt;
    const lastActivityAt = newestEntry?.occurredAt ?? site.createdAt;

    return {
      totalEntries,
      reportCount: countForKind(SiteHistoryEntryKind.REPORT_SUBMITTED),
      cleanupCount: countForKind(SiteHistoryEntryKind.CLEANUP_EVENT_COMPLETED),
      currentStatus: site.status,
      firstActivityAt: firstActivityAt.toISOString(),
      lastActivityAt: lastActivityAt.toISOString(),
    };
  }
}
