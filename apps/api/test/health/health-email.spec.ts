/// <reference types="jest" />

import { EmailPipelineHealthService } from '../../src/email/services/email-pipeline-health.service';
import { WorkerHeartbeatRegistry } from '../../src/observability/worker-heartbeat.registry';

describe('EmailPipelineHealthService', () => {
  const prisma = {
    emailOutbox: {
      count: jest.fn().mockResolvedValue(0),
    },
  };

  const emailEligibility = {
    isGloballyEnabled: jest.fn().mockResolvedValue(true),
  };

  const service = new EmailPipelineHealthService(prisma as never, emailEligibility as never);

  beforeEach(() => {
    jest.clearAllMocks();
    WorkerHeartbeatRegistry.resetForTests();
  });

  it('returns disabled when email is globally disabled', async () => {
    emailEligibility.isGloballyEnabled.mockResolvedValueOnce(false);
    const snapshot = await service.getHealthSnapshot();
    expect(snapshot.status).toBe('disabled');
    expect(snapshot.emailEnabled).toBe(false);
    expect(snapshot.alerts).toEqual([]);
  });

  it('uses database counts for queue depth alerts', async () => {
    emailEligibility.isGloballyEnabled.mockResolvedValueOnce(true);
    prisma.emailOutbox.count.mockResolvedValueOnce(55).mockResolvedValueOnce(2);

    const snapshot = await service.getHealthSnapshot();

    expect(snapshot.outbox.pending).toBe(55);
    expect(snapshot.outbox.deadLetter).toBe(2);
    expect(snapshot.alerts).toContain('email_queue_depth_critical:55');
  });

  it('marks degraded when worker is expected but stale', async () => {
    emailEligibility.isGloballyEnabled.mockResolvedValueOnce(true);
    const snapshot = await service.getHealthSnapshot();
    expect(snapshot.status).toBe('degraded');
    expect(snapshot.worker.stale).toBe(true);
    expect(snapshot.alerts).toContain('email_worker_stale');
  });
});
