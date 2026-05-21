import { SiteHistoryEntryKind, SiteStatus } from '../../src/prisma-client';
import { SiteHistoryWriterService } from '../../src/sites/history/site-history-writer.service';

describe('SiteHistoryWriterService', () => {
  const siteEventsService = { emitSiteUpdated: jest.fn() };
  const prisma = {
    siteHistoryEntry: {
      create: jest.fn().mockResolvedValue({ id: 'entry-1', siteId: 'site-1' }),
    },
  };

  let writer: SiteHistoryWriterService;

  beforeEach(() => {
    jest.clearAllMocks();
    writer = new SiteHistoryWriterService(prisma as never, siteEventsService as never);
  });

  it('records site created without emitting SSE inside transaction', async () => {
    const tx = {
      siteHistoryEntry: {
        create: jest.fn().mockResolvedValue({ id: 'e-tx', siteId: 'site-1' }),
      },
    };

    await writer.recordSiteCreated({ siteId: 'site-1' }, tx as never);

    expect(tx.siteHistoryEntry.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          kind: SiteHistoryEntryKind.SITE_CREATED,
          toStatus: SiteStatus.REPORTED,
        }),
      }),
    );
    expect(siteEventsService.emitSiteUpdated).not.toHaveBeenCalled();
  });

  it('emits SSE after admin note outside transaction', async () => {
    await writer.recordAdminNote({
      siteId: 'site-1',
      note: 'Verified on site visit',
      actor: { userId: 'admin-1', role: 'ADMIN' },
    });

    expect(prisma.siteHistoryEntry.create).toHaveBeenCalled();
    expect(siteEventsService.emitSiteUpdated).toHaveBeenCalledWith('site-1', {
      kind: 'updated',
    });
  });
});
