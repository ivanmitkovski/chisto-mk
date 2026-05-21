import { NotFoundException } from '@nestjs/common';
import { SiteHistoryEntryKind } from '../../src/prisma-client';
import { SiteHistoryQueryService } from '../../src/sites/history/site-history-query.service';

describe('SiteHistoryQueryService', () => {
  const siteId = 'cmpbcl4em002b01xhiqf4x2v5';
  const createdAt = new Date('2026-05-18T15:17:17.326Z');

  const prisma = {
    site: { findUnique: jest.fn() },
    siteHistoryEntry: { findFirst: jest.fn(), findMany: jest.fn() },
    user: { findMany: jest.fn() },
    report: { findMany: jest.fn() },
  };

  const service = new SiteHistoryQueryService(prisma as never);

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.user.findMany.mockResolvedValue([]);
    prisma.report.findMany.mockResolvedValue([]);
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
  });
});
