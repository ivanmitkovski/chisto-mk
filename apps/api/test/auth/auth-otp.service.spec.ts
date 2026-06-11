/// <reference types="jest" />

import { AuthOtpService } from '../../src/auth/services/auth-otp.service';

describe('AuthOtpService', () => {
  it('verifyPhoneAndIssueSession forwards rememberMe to session builder', async () => {
    const buildAuthResponse = jest.fn().mockResolvedValue({
      accessToken: 'access',
      refreshToken: 'refresh',
      user: { id: 'user-1' },
    });
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'user-1',
          isPhoneVerified: true,
        }),
        findMany: jest.fn().mockResolvedValue([]),
        update: jest.fn().mockResolvedValue({
          id: 'user-1',
          email: 'u@chisto.mk',
          firstName: 'A',
        }),
      },
      userDeviceToken: {
        findMany: jest.fn().mockResolvedValue([]),
      },
    };
    const otpService = { verifyAndConsumeOtp: jest.fn().mockResolvedValue(undefined) };
    const otpSender = { send: jest.fn() };
    const audit = { log: jest.fn().mockResolvedValue(undefined) };
    const emailService = { sendAuthTemplate: jest.fn().mockResolvedValue(undefined) };
    const sessionService = { buildAuthResponse };
    const env = { shouldReturnDevCode: false };
    const identifierThrottle = { assertAllowed: jest.fn() };

    const svc = new AuthOtpService(
      prisma as never,
      otpService as never,
      otpSender as never,
      sessionService as never,
      audit as never,
      emailService as never,
      env as never,
      identifierThrottle as never,
      { emit: jest.fn() } as never,
    );

    await svc.verifyPhoneAndIssueSession('+38970123456', '123456', false, 'device-1');

    expect(buildAuthResponse).toHaveBeenCalledWith(
      expect.objectContaining({ id: 'user-1' }),
      false,
      { deviceId: 'device-1', ipAddress: null },
    );
  });
});
