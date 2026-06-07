/// <reference types="jest" />
import { AdminBroadcastScheduleWorkerService } from '../../src/admin-control/services/admin-broadcast-schedule-worker.service';

describe('AdminBroadcastScheduleWorkerService', () => {
  it('auto-sends due scheduled campaigns', async () => {
    const due = {
      id: 'bc-due',
      title: 'Due',
      body: 'Body',
      type: 'SYSTEM',
      audience: 'all' as const,
      status: 'scheduled' as const,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    const broadcasts = {
      listDueScheduled: jest.fn().mockResolvedValue([due]),
    };
    const dispatch = {
      send: jest.fn().mockResolvedValue({ sentCount: 2, failedCount: 0 }),
    };
    const worker = new AdminBroadcastScheduleWorkerService(
      broadcasts as never,
      dispatch as never,
    );
    (worker as unknown as { isLeader: boolean }).isLeader = true;

    await worker.runTick();

    expect(dispatch.send).toHaveBeenCalledWith('bc-due');
  });

  it('skips tick when not leader', async () => {
    const broadcasts = {
      listDueScheduled: jest.fn(),
    };
    const dispatch = {
      send: jest.fn(),
    };
    const worker = new AdminBroadcastScheduleWorkerService(
      broadcasts as never,
      dispatch as never,
    );
    (worker as unknown as { isLeader: boolean }).isLeader = false;

    await worker.runTick();

    expect(broadcasts.listDueScheduled).not.toHaveBeenCalled();
    expect(dispatch.send).not.toHaveBeenCalled();
  });
});
