/// <reference types="jest" />

import { BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AuthCredentialService } from '../../src/auth/auth-credential.service';
import { loadAuthEnvRuntime } from '../../src/auth/auth-env.config';
import { AuditService } from '../../src/audit/audit.service';
import { OtpService } from '../../src/otp/otp.service';
import { OtpSmsPurpose } from '../../src/otp/otp-sender.interface';

describe('AuthCredentialService', () => {
  const audit = { log: jest.fn().mockResolvedValue(undefined) } as unknown as AuditService;
  const env = loadAuthEnvRuntime(null as unknown as ConfigService);
  const otpService = {} as OtpService;
  const otpSender = { sendOtp: jest.fn().mockResolvedValue(undefined) };

  it('sendOtp rejects unknown phone numbers', async () => {
    const prisma = {
      user: { findUnique: jest.fn().mockResolvedValue(null) },
      phoneOtp: { upsert: jest.fn() },
    } as never;
    const svc = new AuthCredentialService(prisma, otpService, otpSender as never, audit, env);
    await expect(
      svc.sendOtp('+38970999999', { purpose: OtpSmsPurpose.PhoneVerification }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect((prisma as { phoneOtp: { upsert: jest.Mock } }).phoneOtp.upsert).not.toHaveBeenCalled();
  });
});
