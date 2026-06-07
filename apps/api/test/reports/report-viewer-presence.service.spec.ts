/// <reference types="jest" />
import { NotFoundException } from '@nestjs/common';
import { ReportViewerPresenceService } from '../../src/reports/services/report-viewer-presence.service';

describe('ReportViewerPresenceService', () => {
  const actor = { userId: 'mod-1', email: 'mod@example.com' };

  function createService(options?: { reportExists?: boolean }) {
    const prisma: any = {
      report: {
        findUnique: jest.fn().mockResolvedValue(options?.reportExists === false ? null : { id: 'r1' }),
      },
    };
    const presenceEvents = {
      publish: jest.fn(),
    };
    const service = new ReportViewerPresenceService(prisma, presenceEvents as never);
    return { service, prisma, presenceEvents };
  }

  beforeEach(() => {
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('registers a viewer on heartbeat and emits debounced SSE update', async () => {
    const { service, presenceEvents } = createService();

    const viewers = await service.heartbeat('r1', actor as never, {
      sessionId: 'sess-1',
      displayName: 'Ada Lovelace',
    });

    expect(viewers).toEqual([
      { sessionId: 'sess-1', userId: 'mod-1', displayName: 'Ada Lovelace' },
    ]);

    jest.advanceTimersByTime(300);
    expect(presenceEvents.publish).toHaveBeenCalledWith({
      type: 'report_viewers_updated',
      reportId: 'r1',
      viewers: [{ sessionId: 'sess-1', userId: 'mod-1', displayName: 'Ada Lovelace' }],
    });
  });

  it('throws when report does not exist on heartbeat', async () => {
    const { service } = createService({ reportExists: false });

    await expect(
      service.heartbeat('missing', actor as never, {
        sessionId: 'sess-1',
        displayName: 'Ada',
      }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('prunes expired sessions on list', async () => {
    const { service } = createService();

    await service.heartbeat('r1', actor as never, {
      sessionId: 'sess-1',
      displayName: 'Ada Lovelace',
    });

    jest.advanceTimersByTime(46_000);

    const viewers = await service.list('r1');
    expect(viewers).toEqual([]);
  });

  it('removes session on leave for the owning user', async () => {
    const { service, presenceEvents } = createService();

    await service.heartbeat('r1', actor as never, {
      sessionId: 'sess-1',
      displayName: 'Ada Lovelace',
    });

    jest.advanceTimersByTime(300);
    presenceEvents.publish.mockClear();

    const viewers = await service.leave('r1', 'sess-1', 'mod-1');
    expect(viewers).toEqual([]);

    jest.advanceTimersByTime(300);
    expect(presenceEvents.publish).toHaveBeenCalledWith({
      type: 'report_viewers_updated',
      reportId: 'r1',
      viewers: [],
    });
  });

  it('does not remove another user session on leave', async () => {
    const { service } = createService();

    await service.heartbeat('r1', actor as never, {
      sessionId: 'sess-1',
      displayName: 'Ada Lovelace',
    });

    const viewers = await service.leave('r1', 'sess-1', 'other-user');
    expect(viewers).toHaveLength(1);
    expect(viewers[0]?.sessionId).toBe('sess-1');
  });

  it('falls back to email when displayName is blank', async () => {
    const { service } = createService();

    const viewers = await service.heartbeat('r1', actor as never, {
      sessionId: 'sess-1',
      displayName: '   ',
    });

    expect(viewers[0]?.displayName).toBe('mod@example.com');
  });
});
