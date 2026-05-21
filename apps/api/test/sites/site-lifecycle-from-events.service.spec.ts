import { EcoEventLifecycleStatus, SiteStatus } from '../../src/prisma-client';
import { SiteLifecycleFromEventsService } from '../../src/sites/site-lifecycle-from-events.service';

describe('SiteLifecycleFromEventsService', () => {
  const featureFlags = { getPublicMap: jest.fn().mockResolvedValue({ site_lifecycle_from_events: true }) };
  const historyWriter = {
    recordStatusChanged: jest.fn().mockResolvedValue({ id: 'h5' }),
    emitHistoryAppended: jest.fn(),
  };
  const historyEventRecorder = {
    recordEventScheduled: jest.fn().mockResolvedValue({ id: 'h1' }),
    recordEventStarted: jest.fn().mockResolvedValue({ id: 'h2' }),
    recordEventCompleted: jest.fn().mockResolvedValue({ id: 'h3' }),
    recordEventCancelled: jest.fn().mockResolvedValue({ id: 'h4' }),
  };
  const audit = { log: jest.fn().mockResolvedValue(undefined) };
  const siteEventsService = { emitSiteUpdated: jest.fn() };
  const sitesFeed = { invalidateFeedCache: jest.fn() };
  const sitesMapQuery = { invalidateMapCache: jest.fn() };

  const prisma = {
    site: {
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    cleanupEvent: { count: jest.fn() },
  };

  let service: SiteLifecycleFromEventsService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new SiteLifecycleFromEventsService(
      prisma as never,
      featureFlags as never,
      historyWriter as never,
      historyEventRecorder as never,
      audit as never,
      siteEventsService as never,
      sitesFeed as never,
      sitesMapQuery as never,
    );
  });

  it('transitions REPORTED to CLEANUP_SCHEDULED when event is linked', async () => {
    prisma.site.findUnique.mockResolvedValue({ id: 's1', status: SiteStatus.REPORTED });
    prisma.site.update.mockResolvedValue({
      id: 's1',
      status: SiteStatus.CLEANUP_SCHEDULED,
      latitude: 1,
      longitude: 2,
      updatedAt: new Date(),
    });

    await service.onEventLinkedToSite('s1', 'ev-1');

    expect(prisma.site.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: { status: SiteStatus.CLEANUP_SCHEDULED },
      }),
    );
    expect(historyWriter.recordStatusChanged).toHaveBeenCalled();
    expect(historyEventRecorder.recordEventScheduled).toHaveBeenCalled();
  });

  it('does not auto-transition to CLEANED on event completed', async () => {
    await service.onEventLifecycleChanged(
      's1',
      'ev-1',
      EcoEventLifecycleStatus.COMPLETED,
    );

    expect(prisma.site.update).not.toHaveBeenCalled();
    expect(historyEventRecorder.recordEventCompleted).toHaveBeenCalled();
  });

  it('reverts to VERIFIED on cancel when no other active events', async () => {
    prisma.site.findUnique.mockResolvedValue({ status: SiteStatus.IN_PROGRESS });
    prisma.cleanupEvent.count.mockResolvedValue(0);
    prisma.site.update.mockResolvedValue({
      id: 's1',
      status: SiteStatus.VERIFIED,
      latitude: 1,
      longitude: 2,
      updatedAt: new Date(),
    });

    await service.onEventLifecycleChanged(
      's1',
      'ev-1',
      EcoEventLifecycleStatus.CANCELLED,
    );

    expect(prisma.site.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: { status: SiteStatus.VERIFIED } }),
    );
  });
});
