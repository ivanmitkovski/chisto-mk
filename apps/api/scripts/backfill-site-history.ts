/**
 * Idempotent backfill of SiteHistoryEntry from existing Site, Report, CleanupEvent, AuditLog rows.
 * Skips sites that already have at least one history entry.
 *
 * Usage: npm run backfill:site-history
 */
import {
  EcoEventLifecycleStatus,
  PrismaClient,
  ReportStatus,
  SiteHistoryEntryKind,
  SiteStatus,
} from '../src/generated/prisma';

const prisma = new PrismaClient();

type DraftEntry = {
  siteId: string;
  kind: SiteHistoryEntryKind;
  occurredAt: Date;
  fromStatus?: SiteStatus | null;
  toStatus?: SiteStatus | null;
  reportId?: string | null;
  cleanupEventId?: string | null;
  actorUserId?: string | null;
  actorRole?: string | null;
  note?: string | null;
  metadata?: object;
};

async function main() {
  let cursor: string | undefined;
  const batch = 100;
  let sitesProcessed = 0;
  let entriesCreated = 0;

  while (true) {
    const sites = await prisma.site.findMany({
      where: cursor ? { id: { gt: cursor } } : undefined,
      orderBy: { id: 'asc' },
      take: batch,
      select: { id: true, createdAt: true, status: true },
    });
    if (sites.length === 0) break;

    for (const site of sites) {
      const existing = await prisma.siteHistoryEntry.count({
        where: { siteId: site.id },
        take: 1,
      });
      if (existing > 0) {
        continue;
      }

      const drafts: DraftEntry[] = [];

      drafts.push({
        siteId: site.id,
        kind: SiteHistoryEntryKind.SITE_CREATED,
        occurredAt: site.createdAt,
        toStatus: SiteStatus.REPORTED,
      });

      const reports = await prisma.report.findMany({
        where: { siteId: site.id },
        orderBy: { createdAt: 'asc' },
        select: {
          id: true,
          createdAt: true,
          status: true,
          moderatedAt: true,
          reporterId: true,
          moderatedById: true,
        },
      });

      for (const report of reports) {
        drafts.push({
          siteId: site.id,
          kind: SiteHistoryEntryKind.REPORT_SUBMITTED,
          occurredAt: report.createdAt,
          reportId: report.id,
          actorUserId: report.reporterId,
          actorRole: 'user',
        });
        if (report.status === ReportStatus.APPROVED && report.moderatedAt) {
          drafts.push({
            siteId: site.id,
            kind: SiteHistoryEntryKind.REPORT_APPROVED,
            occurredAt: report.moderatedAt,
            reportId: report.id,
            actorUserId: report.moderatedById,
            actorRole: 'admin',
          });
        }
        if (report.status === ReportStatus.REJECTED && report.moderatedAt) {
          drafts.push({
            siteId: site.id,
            kind: SiteHistoryEntryKind.REPORT_REJECTED,
            occurredAt: report.moderatedAt,
            reportId: report.id,
            actorUserId: report.moderatedById,
            actorRole: 'admin',
          });
        }
      }

      const events = await prisma.cleanupEvent.findMany({
        where: { siteId: site.id },
        orderBy: { createdAt: 'asc' },
        select: {
          id: true,
          createdAt: true,
          lifecycleStatus: true,
          completedAt: true,
          organizerId: true,
        },
      });

      for (const event of events) {
        drafts.push({
          siteId: site.id,
          kind: SiteHistoryEntryKind.CLEANUP_EVENT_SCHEDULED,
          occurredAt: event.createdAt,
          cleanupEventId: event.id,
          actorUserId: event.organizerId,
          actorRole: 'user',
        });
        if (
          event.lifecycleStatus === EcoEventLifecycleStatus.IN_PROGRESS ||
          event.lifecycleStatus === EcoEventLifecycleStatus.COMPLETED ||
          event.lifecycleStatus === EcoEventLifecycleStatus.CANCELLED
        ) {
          drafts.push({
            siteId: site.id,
            kind: SiteHistoryEntryKind.CLEANUP_EVENT_STARTED,
            occurredAt: event.createdAt,
            cleanupEventId: event.id,
          });
        }
        if (event.lifecycleStatus === EcoEventLifecycleStatus.COMPLETED && event.completedAt) {
          drafts.push({
            siteId: site.id,
            kind: SiteHistoryEntryKind.CLEANUP_EVENT_COMPLETED,
            occurredAt: event.completedAt,
            cleanupEventId: event.id,
          });
        }
        if (event.lifecycleStatus === EcoEventLifecycleStatus.CANCELLED) {
          drafts.push({
            siteId: site.id,
            kind: SiteHistoryEntryKind.CLEANUP_EVENT_CANCELLED,
            occurredAt: event.completedAt ?? event.createdAt,
            cleanupEventId: event.id,
          });
        }
      }

      const auditRows = await prisma.auditLog.findMany({
        where: {
          resourceType: 'Site',
          resourceId: site.id,
          action: { in: ['SITE_STATUS_UPDATED', 'SITE_ARCHIVED', 'SITE_UNARCHIVED'] },
        },
        orderBy: { createdAt: 'asc' },
        select: {
          action: true,
          createdAt: true,
          actorId: true,
          metadata: true,
        },
      });

      for (const log of auditRows) {
        const meta = log.metadata as { from?: SiteStatus; to?: SiteStatus; reason?: string } | null;
        if (log.action === 'SITE_STATUS_UPDATED' && meta?.from && meta?.to) {
          drafts.push({
            siteId: site.id,
            kind: SiteHistoryEntryKind.STATUS_CHANGED,
            occurredAt: log.createdAt,
            fromStatus: meta.from,
            toStatus: meta.to,
            actorUserId: log.actorId,
            actorRole: log.actorId ? 'admin' : 'system',
            metadata: { backfill: true },
          });
        } else if (log.action === 'SITE_ARCHIVED') {
          drafts.push({
            siteId: site.id,
            kind: SiteHistoryEntryKind.ARCHIVED_BY_ADMIN,
            occurredAt: log.createdAt,
            actorUserId: log.actorId,
            actorRole: 'admin',
            note: meta?.reason ?? null,
          });
        } else if (log.action === 'SITE_UNARCHIVED') {
          drafts.push({
            siteId: site.id,
            kind: SiteHistoryEntryKind.UNARCHIVED_BY_ADMIN,
            occurredAt: log.createdAt,
            actorUserId: log.actorId,
            actorRole: 'admin',
          });
        }
      }

      drafts.sort((a, b) => a.occurredAt.getTime() - b.occurredAt.getTime());

      if (drafts.length > 0) {
        await prisma.siteHistoryEntry.createMany({
          data: drafts.map((d) => ({
            siteId: d.siteId,
            kind: d.kind,
            occurredAt: d.occurredAt,
            fromStatus: d.fromStatus ?? null,
            toStatus: d.toStatus ?? null,
            reportId: d.reportId ?? null,
            cleanupEventId: d.cleanupEventId ?? null,
            actorUserId: d.actorUserId ?? null,
            actorRole: d.actorRole ?? null,
            note: d.note ?? null,
            ...(d.metadata ? { metadata: d.metadata } : {}),
          })),
        });
        entriesCreated += drafts.length;
      }

      sitesProcessed += 1;
    }

    cursor = sites[sites.length - 1]!.id;
    console.log(`batch done; sitesProcessed=${sitesProcessed} entriesCreated=${entriesCreated}`);
  }

  console.log(`Backfill complete. sitesProcessed=${sitesProcessed} entriesCreated=${entriesCreated}`);
}

main()
  .catch((err) => {
    console.error(err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
