import { NotFoundException } from '@nestjs/common';
import { SiteHistoryEntryKind } from '../../src/prisma-client';
import { SiteHistoryQueryService } from '../../src/sites/history/site-history-query.service';

describe('SiteHistoryQueryService', () => {
  const siteId = 'cmpbcl4em002b01xhiqf4x2v5';
  const createdAt = new Date('2026-05-18T15:17:17.326Z');
  const entryId = 'cmpbcl4em002b01xhiqf4x2v6';
  const entryOccurredAt = new Date('2026-05-20T10:00:00.000Z');

  const prisma = {
    site: { findUnique: jest.fn() },
    siteHistoryEntry: {
      findFirst: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      groupBy: jest.fn(),
    },
    user: { findMany: jest.fn() },
    report: { findMany: jest.fn() },
  };

  const service = new SiteHistoryQueryService(prisma as never);

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.user.findMany.mockResolvedValue([]);
    prisma.report.findMany.mockResolvedValue([]);
    prisma.siteHistoryEntry.count.mockResolvedValue(0);
    prisma.siteHistoryEntry.groupBy.mockResolvedValue([]);
    prisma.siteHistoryEntry.findFirst.mockResolvedValue(null);
  });

  it('throws SITE_NOT_FOUND when site does not exist', async () => {
    prisma.site.findUnique.mockResolvedValue(null);
    await expect(service.list('missing', {})).rejects.toBeInstanceOf(NotFoundException);
  });

  it('returns synthetic SITE_CREATED when there are no persisted entries', async () => {
    prisma.site.findUnique.mockResolvedValue({
      id: siteId,
      createdAt,
      status: 'VERIFIED',
    });
    prisma.siteHistoryEntry.findMany.mockResolvedValue([]);

    const result = await service.list(siteId, { limit: 30 });

    expect(result.items).toHaveLength(1);
    expect(result.items[0]).toMatchObject({
      kind: SiteHistoryEntryKind.SITE_CREATED,
      toStatus: 'VERIFIED',
      metadata: { synthetic: true },
    });
    expect(result.nextBeforeId).toBeNull();
    expect(result.summary).toMatchObject({
      totalEntries: 0,
      reportCount: 0,
      cleanupCount: 0,
      currentStatus: 'VERIFIED',
      firstActivityAt: createdAt.toISOString(),
      lastActivityAt: createdAt.toISOString(),
    });
  });

  it('includes summary on first page and omits it when paginating', async () => {
    prisma.site.findUnique.mockResolvedValue({
      id: siteId,
      createdAt,
      status: 'VERIFIED',
    });
    prisma.siteHistoryEntry.findMany.mockResolvedValue([
      {
        id: entryId,
        kind: SiteHistoryEntryKind.REPORT_SUBMITTED,
        occurredAt: entryOccurredAt,
        fromStatus: null,
        toStatus: null,
        reportId: 'report-1',
        cleanupEventId: null,
        actorUserId: null,
        actorRole: null,
        note: null,
        metadata: null,
      },
    ]);
    prisma.siteHistoryEntry.count.mockResolvedValue(1);
    prisma.siteHistoryEntry.groupBy.mockResolvedValue([
      { kind: SiteHistoryEntryKind.REPORT_SUBMITTED, _count: { kind: 1 } },
    ]);
    prisma.siteHistoryEntry.findFirst
      .mockResolvedValueOnce({ occurredAt: entryOccurredAt })
      .mockResolvedValueOnce({ occurredAt: entryOccurredAt });

    const firstPage = await service.list(siteId, { limit: 30 });
    expect(firstPage.summary).toMatchObject({
      totalEntries: 1,
      reportCount: 1,
      cleanupCount: 0,
      currentStatus: 'VERIFIED',
      firstActivityAt: entryOccurredAt.toISOString(),
      lastActivityAt: entryOccurredAt.toISOString(),
    });

    prisma.siteHistoryEntry.findFirst.mockResolvedValue({ occurredAt: entryOccurredAt });
    prisma.siteHistoryEntry.findMany.mockResolvedValue([]);

    const secondPage = await service.list(siteId, {
      limit: 30,
      beforeId: entryId,
    });
    expect(secondPage.summary).toBeNull();
  });
});
