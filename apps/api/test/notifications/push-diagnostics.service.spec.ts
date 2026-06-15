import { PushDiagnosticsService } from '../../src/notifications/services/push-diagnostics.service';
import { FcmPushService } from '../../src/notifications/services/fcm-push.service';

describe('PushDiagnosticsService', () => {
  const prisma = {
    notificationOutbox: {
      count: jest.fn(),
      groupBy: jest.fn(),
    },
  };

  const fcm = {
    isEnabled: jest.fn().mockReturnValue(true),
    isReady: jest.fn().mockReturnValue(true),
    getProjectId: jest.fn().mockReturnValue('chisto-mk'),
  };

  const service = new PushDiagnosticsService(
    prisma as never,
    fcm as unknown as FcmPushService,
  );

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns diagnostics with remediation for third-party-auth-error', async () => {
    prisma.notificationOutbox.count.mockResolvedValue(3);
    prisma.notificationOutbox.groupBy.mockResolvedValue([
      { lastErrorCode: 'messaging/third-party-auth-error', _count: { _all: 2 } },
      { lastErrorCode: 'messaging/registration-token-not-registered', _count: { _all: 1 } },
    ]);

    const result = await service.getDiagnostics();

    expect(result.fcmEnabled).toBe(true);
    expect(result.fcmReady).toBe(true);
    expect(result.projectId).toBe('chisto-mk');
    expect(result.deadLetterTotal).toBe(3);
    expect(result.topErrorCodes[0]).toEqual({
      code: 'messaging/third-party-auth-error',
      count: 2,
    });
    expect(result.remediation).toContain('Development APNs auth key');
  });
});
