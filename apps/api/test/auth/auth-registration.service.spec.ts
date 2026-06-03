/// <reference types="jest" />

import { ConflictException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { AuthRegistrationService } from '../../src/auth/services/auth-registration.service';
import { AuthOtpService } from '../../src/auth/services/auth-otp.service';
import { loadAuthEnvRuntime } from '../../src/auth/constants/auth-env.config';

describe('AuthRegistrationService', () => {
  it('register rejects duplicate email', async () => {
    const prisma = {
      user: {
        findFirst: jest.fn().mockResolvedValue({ id: 'x', email: 'dup@chisto.mk', phoneNumber: '+38900000001' }),
      },
    } as never;
    const emitter = { emit: jest.fn() } as never;
    const authOtp = { sendPhoneVerificationOtp: jest.fn() } as unknown as AuthOtpService;
    const env = loadAuthEnvRuntime(null as unknown as ConfigService);
    const configService = {
      get: jest.fn((key: string) => (key === 'TERMS_VERSION' ? '1' : undefined)),
    } as unknown as ConfigService;
    const registration = new AuthRegistrationService(
      prisma,
      emitter as unknown as EventEmitter2,
      authOtp,
      env,
      configService,
    );
    await expect(
      registration.register({
        firstName: 'A',
        lastName: 'B',
        email: 'dup@chisto.mk',
        phoneNumber: '+38970111111',
        password: 'StrongPass123!',
        termsAcceptedAt: new Date().toISOString(),
        termsVersion: '1',
      }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('register passes through devCode when OTP service returns it', async () => {
    const prisma = {
      user: {
        findFirst: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockResolvedValue({
          id: 'user-1',
          phoneNumber: '+38970111111',
        }),
      },
    } as never;
    const emitter = { emit: jest.fn() } as never;
    const authOtp = {
      sendPhoneVerificationOtp: jest.fn().mockResolvedValue({ devCode: '123456' }),
    } as unknown as AuthOtpService;
    const env = loadAuthEnvRuntime(null as unknown as ConfigService);
    const configService = {
      get: jest.fn((key: string) => (key === 'TERMS_VERSION' ? '1' : undefined)),
    } as unknown as ConfigService;
    const registration = new AuthRegistrationService(
      prisma,
      emitter as unknown as EventEmitter2,
      authOtp,
      env,
      configService,
    );
    const result = await registration.register({
      firstName: 'A',
      lastName: 'B',
      email: 'new@chisto.mk',
      phoneNumber: '+38970111111',
      password: 'StrongPass123!',
      termsAcceptedAt: new Date().toISOString(),
      termsVersion: '1',
    });
    expect(result.devCode).toBe('123456');
    expect(authOtp.sendPhoneVerificationOtp).toHaveBeenCalledWith('+38970111111', undefined);
  });
});
