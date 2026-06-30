/// <reference types="jest" />
import { WorkerHeartbeatRegistry } from '../../src/observability/worker-heartbeat.registry';

describe('WorkerHeartbeatRegistry', () => {
  beforeEach(() => {
    WorkerHeartbeatRegistry.resetForTests();
  });

  it('marks workers stale when last run exceeds twice the interval', () => {
    WorkerHeartbeatRegistry.markStarted({ name: 'email-delivery', intervalMs: 10_000 });
    WorkerHeartbeatRegistry.record('email-delivery', { ok: true });

    const [worker] = WorkerHeartbeatRegistry.snapshot();
    expect(worker.stale).toBe(false);

    const staleWorker = WorkerHeartbeatRegistry.snapshot().find((item) => item.name === 'email-delivery');
    expect(staleWorker).toBeDefined();

    jest.useFakeTimers();
    jest.setSystemTime(Date.now() + 25_000);
    const afterDelay = WorkerHeartbeatRegistry.snapshot().find((item) => item.name === 'email-delivery');
    expect(afterDelay?.stale).toBe(true);
    jest.useRealTimers();
  });
});
