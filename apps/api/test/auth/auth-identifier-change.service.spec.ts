/// <reference types="jest" />
import { AuthIdentifierChangeService } from '../../src/auth/services/auth-identifier-change.service';

describe('AuthIdentifierChangeService', () => {
  it('requestEmailChange rejects duplicate email', async () => {
    const prisma = {
      user: {
        findFirst: jest.fn().mockResolvedValue({ id: 'other' }),
        findUnique: jest.fn().mockResolvedValue({ id: 'u1', email: 'old@test.local', firstName: 'A' }),
      },
    };
    const throttle = { assertAllowed: jest.fn() };
    const email = { sendTemplate: jest.fn() };
    const authSnapshotCache = { invalidate: jest.fn() };
    const audit = { log: jest.fn() };
    const otpSender = { sendOtp: jest.fn() };
    const env = { appPublicUrl: 'https://app.test' };
    const svc = new AuthIdentifierChangeService(
      prisma as never,
      email as never,
      authSnapshotCache as never,
      audit as never,
      throttle as never,
      otpSender as never,
      env as never,
    );
    await expect(svc.requestEmailChange('u1', 'taken@test.local')).rejects.toMatchObject({
      response: { code: 'EMAIL_IN_USE' },
    });
  });
});
