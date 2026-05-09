import { BadRequestException, NotFoundException } from '@nestjs/common';
import { SitesAdminService } from '../../src/sites/sites-admin.service';

function makeService(input?: {
  site?: any;
  auditFindResult?: { metadata: Record<string, unknown> } | null;
  updateManyCount?: number;
}) {
  const prisma = {
    site: {
      findUnique: jest.fn(async () => input?.site ?? null),
      findUniqueOrThrow: jest.fn(async () => input?.site ?? null),
      update: jest.fn(async () => ({
        id: 'site_1',
        status: 'CLEANED',
        latitude: 41.99,
        longitude: 21.43,
        updatedAt: new Date('2026-05-07T11:00:00.000Z'),
        isArchivedByAdmin: true,
      })),
      updateMany: jest.fn(async () => ({ count: input?.updateManyCount ?? 2 })),
    },
  } as any;
  const audit = {
    log: jest.fn(async () => undefined),
    findByActionAndIdempotencyKey: jest.fn(async () => input?.auditFindResult ?? null),
  } as any;
  const siteEventsService = { emitSiteUpdated: jest.fn() } as any;
  const sitesMapQuery = { invalidateMapCache: jest.fn() } as any;
  const sitesFeed = { invalidateFeedCache: jest.fn() } as any;
  return {
    service: new SitesAdminService(prisma, audit, siteEventsService, sitesMapQuery, sitesFeed),
    prisma,
    audit,
    siteEventsService,
    sitesMapQuery,
    sitesFeed,
  };
}

describe('SitesAdminService archive moderation', () => {

  it('rejects archive without reason', async () => {
    const { service } = makeService({
      site: { id: 'site_1', isArchivedByAdmin: false, archiveReason: null },
    });
    await expect(
      service.updateArchiveStatus('site_1', { archived: true }, { userId: 'admin_1' } as any),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('throws not found for missing site', async () => {
    const { service } = makeService();
    await expect(
      service.updateArchiveStatus(
        'missing',
        { archived: true, reason: 'x' },
        { userId: 'admin_1' } as any,
      ),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('archives site and writes audit/event/cache side effects', async () => {
    const { service, prisma, audit, siteEventsService, sitesFeed, sitesMapQuery } = makeService({
      site: { id: 'site_1', isArchivedByAdmin: false, archiveReason: null },
    });
    await service.updateArchiveStatus(
      'site_1',
      { archived: true, reason: 'Duplicate historic record' },
      { userId: 'admin_1' } as any,
    );
    expect(prisma.site.update).toHaveBeenCalled();
    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'SITE_ARCHIVED', resourceId: 'site_1' }),
    );
    expect(siteEventsService.emitSiteUpdated).toHaveBeenCalled();
    expect(sitesFeed.invalidateFeedCache).toHaveBeenCalledWith('site_archived');
    expect(sitesMapQuery.invalidateMapCache).toHaveBeenCalledWith('site_archived', 'site_1');
  });
});

describe('SitesAdminService bulkSites idempotency', () => {
  const admin = { userId: 'admin_1' } as any;

  it('returns cached result when idempotencyKey already exists', async () => {
    const { service, prisma, audit } = makeService({
      auditFindResult: {
        metadata: { updated: 3, siteIds: ['s1', 's2', 's3'], idempotencyKey: 'key-1' },
      },
    });

    const result = await service.bulkSites(
      { action: 'set_status', siteIds: ['s1', 's2', 's3'], status: 'VERIFIED' as any, idempotencyKey: 'key-1' },
      admin,
    );

    expect(result).toEqual({ updated: 3, siteIds: ['s1', 's2', 's3'] });
    expect(audit.findByActionAndIdempotencyKey).toHaveBeenCalledWith('SITES_BULK_UPDATE', 'key-1');
    expect(prisma.site.updateMany).not.toHaveBeenCalled();
    expect(audit.log).not.toHaveBeenCalled();
  });

  it('executes normally when no idempotencyKey is provided', async () => {
    const { service, prisma, audit } = makeService({ updateManyCount: 2 });

    const result = await service.bulkSites(
      { action: 'set_status', siteIds: ['s1', 's2'], status: 'VERIFIED' as any },
      admin,
    );

    expect(result).toEqual({ updated: 2, siteIds: ['s1', 's2'] });
    expect(audit.findByActionAndIdempotencyKey).not.toHaveBeenCalled();
    expect(prisma.site.updateMany).toHaveBeenCalled();
    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({
        action: 'SITES_BULK_UPDATE',
        metadata: expect.objectContaining({ updated: 2, siteIds: ['s1', 's2'] }),
      }),
    );
  });

  it('executes and records when idempotencyKey is new', async () => {
    const { service, prisma, audit } = makeService({ updateManyCount: 3 });

    const result = await service.bulkSites(
      { action: 'set_status', siteIds: ['s1', 's2', 's3'], status: 'CLEANED' as any, idempotencyKey: 'new-key' },
      admin,
    );

    expect(result).toEqual({ updated: 3, siteIds: ['s1', 's2', 's3'] });
    expect(audit.findByActionAndIdempotencyKey).toHaveBeenCalledWith('SITES_BULK_UPDATE', 'new-key');
    expect(prisma.site.updateMany).toHaveBeenCalled();
    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({
        action: 'SITES_BULK_UPDATE',
        metadata: expect.objectContaining({
          idempotencyKey: 'new-key',
          updated: 3,
          siteIds: ['s1', 's2', 's3'],
        }),
      }),
    );
  });

  it('returns actual updateMany count instead of siteIds.length', async () => {
    const { service } = makeService({ updateManyCount: 1 });

    const result = await service.bulkSites(
      { action: 'set_status', siteIds: ['s1', 's2', 's3'], status: 'VERIFIED' as any },
      admin,
    );

    expect(result.updated).toBe(1);
    expect(result.siteIds).toHaveLength(3);
  });

  it('deduplicates siteIds', async () => {
    const { service, prisma } = makeService({ updateManyCount: 1 });

    await service.bulkSites(
      { action: 'set_status', siteIds: ['s1', 's1', 's2'], status: 'VERIFIED' as any },
      admin,
    );

    expect(prisma.site.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: { in: ['s1', 's2'] } },
      }),
    );
  });
});
