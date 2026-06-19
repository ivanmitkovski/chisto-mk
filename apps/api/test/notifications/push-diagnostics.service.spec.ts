import { PushDiagnosticsService } from '../../src/notifications/services/push-diagnostics.service';
import { FcmPushService } from '../../src/notifications/services/fcm-push.service';
import { PushPipelineHealthService } from '../../src/notifications/services/push-pipeline-health.service';

describe('PushDiagnosticsService', () => {
  const prisma = {
    notificationOutbox: {
      count: jest.fn(),
      groupBy: jest.fn(),
    },
    userDeviceToken: {
      count: jest.fn(),
    },
  };

  const fcm = {
    isEnabled: jest.fn().mockReturnValue(true),
    isReady: jest.fn().mockReturnValue(true),
    getProjectId: jest.fn().mockReturnValue('chisto-mk'),
    getCredentialValidation: jest.fn().mockReturnValue({
      status: 'valid',
      projectId: 'chisto-mk',
      parseError: null,
    }),
  };

  const pipelineHealth = {
    getHealthSnapshot: jest.fn().mockResolvedValue({
      outbox: { pending: 2, leased: 1, deadLetter: 3, oldestPendingAgeSec: null },
      worker: { expected: true, running: true, stale: false },
    }),
  };

  const service = new PushDiagnosticsService(
    prisma as never,
    fcm as unknown as FcmPushService,
    pipelineHealth as unknown as PushPipelineHealthService,
  );

  beforeEach(() => {
    jest.clearAllMocks();
    pipelineHealth.getHealthSnapshot.mockResolvedValue({
      outbox: { pending: 2, leased: 1, deadLetter: 3, oldestPendingAgeSec: null },
      worker: { expected: true, running: true, stale: false },
    });
  });

  it('returns diagnostics with remediation for third-party-auth-error', async () => {
    prisma.notificationOutbox.count.mockResolvedValue(3);
    prisma.notificationOutbox.groupBy.mockResolvedValue([
      { lastErrorCode: 'messaging/third-party-auth-error', _count: { _all: 2 } },
      { lastErrorCode: 'messaging/registration-token-not-registered', _count: { _all: 1 } },
    ]);
    prisma.userDeviceToken.count.mockResolvedValue(12);

    const result = await service.getDiagnostics();

    expect(result.fcmEnabled).toBe(true);
    expect(result.fcmReady).toBe(true);
    expect(result.projectId).toBe('chisto-mk');
    expect(result.deadLetterTotal).toBe(3);
    expect(result.registeredDeviceTokens).toBe(12);
    expect(result.topErrorCodes[0]).toEqual({
      code: 'messaging/third-party-auth-error',
      count: 2,
    });
    expect(result.remediation).toContain('Development APNs auth key');
  });
});
