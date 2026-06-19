/// <reference types="jest" />

import { PushPipelineHealthService } from '../../src/notifications/services/push-pipeline-health.service';
import { CircuitState } from '../../src/common/resilience/circuit-breaker';

describe('PushPipelineHealthService', () => {
  const fcm = {
    isEnabled: jest.fn().mockReturnValue(true),
    isReady: jest.fn().mockReturnValue(false),
    getProjectId: jest.fn().mockReturnValue(null),
    getCredentialValidation: jest.fn().mockReturnValue({
      status: 'invalid_json',
      projectId: null,
      parseError: 'Unexpected token',
    }),
    getCircuitBreakerState: jest.fn().mockReturnValue(CircuitState.CLOSED),
  };

  const prisma = {
    notificationOutbox: {
      count: jest.fn().mockResolvedValue(0),
      findFirst: jest.fn().mockResolvedValue(null),
    },
  };

  const pushWorker = {
    getPgListenerStatus: jest.fn().mockReturnValue({ enabled: true, connected: false }),
  };

  const service = new PushPipelineHealthService(
    fcm as never,
    prisma as never,
    pushWorker as never,
  );

  it('marks degraded when FCM enabled but not ready', async () => {
    const snapshot = await service.getHealthSnapshot();
    expect(snapshot.status).toBe('degraded');
    expect(snapshot.alerts).toContain('fcm_enabled_not_ready');
    expect(snapshot.credentialStatus).toBe('invalid_json');
  });
});
