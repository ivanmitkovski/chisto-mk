/// <reference types="jest" />

import { EventEmitter2 } from '@nestjs/event-emitter';
import { NotificationType } from '../../src/prisma-client';
import { AuthOtpService } from '../../src/auth/services/auth-otp.service';

describe('AuthOtpService WELCOME notification', () => {
  const makeService = (overrides?: {
    isPhoneVerified?: boolean;
    existingWelcome?: boolean;
  }) => {
    const isPhoneVerified = overrides?.isPhoneVerified ?? false;
    const eventEmitter = { emit: jest.fn() } as unknown as EventEmitter2;
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'user-1',
          isPhoneVerified,
        }),
        findMany: jest.fn().mockResolvedValue([]),
        update: jest.fn().mockResolvedValue({
          id: 'user-1',
          email: 'a@b.c',
          firstName: 'Test',
          isPhoneVerified: true,
        }),
      },
      userNotification: {
        findFirst: jest.fn().mockResolvedValue(
          overrides?.existingWelcome ? { id: 'n1' } : null,
        ),
      },
      userDeviceToken: {
        findMany: jest.fn().mockResolvedValue([{ userId: 'user-1', locale: 'mk' }]),
      },
    };
    const otpService = { verifyAndConsumeOtp: jest.fn().mockResolvedValue(undefined) };
    const sessionService = {
      buildAuthResponse: jest.fn().mockResolvedValue({ accessToken: 't' }),
    };
    const audit = { log: jest.fn() };
    const emailService = { sendAuthTemplate: jest.fn().mockResolvedValue(undefined) };
    const env = { shouldReturnDevCode: false };

    const service = new AuthOtpService(
      prisma as never,
      otpService as never,
      {} as never,
      sessionService as never,
      audit as never,
      emailService as never,
      env as never,
      { assertAllowed: jest.fn() } as never,
      eventEmitter,
    );
    return { service, eventEmitter, prisma };
  };

  it('emits WELCOME on first phone verification only', async () => {
    const { service, eventEmitter } = makeService({ isPhoneVerified: false });
    await service.verifyPhoneAndIssueSession('+38970000000', '123456');
    await new Promise((r) => setImmediate(r));
    expect(eventEmitter.emit).toHaveBeenCalledWith(
      'notification.send',
      expect.objectContaining({
        type: NotificationType.WELCOME,
        recipientUserIds: ['user-1'],
        threadKey: 'welcome:user-1',
        data: { kind: 'welcome' },
      }),
    );
  });

  it('skips WELCOME when phone was already verified', async () => {
    const { service, eventEmitter } = makeService({ isPhoneVerified: true });
    await service.verifyPhoneAndIssueSession('+38970000000', '123456');
    await new Promise((r) => setImmediate(r));
    expect(eventEmitter.emit).not.toHaveBeenCalled();
  });

  it('skips WELCOME when notification already exists (idempotency)', async () => {
    const { service, eventEmitter } = makeService({
      isPhoneVerified: false,
      existingWelcome: true,
    });
    await service.verifyPhoneAndIssueSession('+38970000000', '123456');
    await new Promise((r) => setImmediate(r));
    expect(eventEmitter.emit).not.toHaveBeenCalled();
  });
});
