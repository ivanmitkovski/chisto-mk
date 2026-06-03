/// <reference types="jest" />

import { UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { AuthSessionService } from '../../src/auth/services/auth-session.service';
import { RefreshTokenRotationService } from '../../src/auth/services/refresh-token-rotation.service';
import { loadAuthEnvRuntime } from '../../src/auth/constants/auth-env.config';

describe('AuthSessionService', () => {
  it('refresh rejects token without dot separator', async () => {
    const prisma = {} as never;
    const jwt = { sign: jest.fn() } as unknown as JwtService;
    const uploads = { signPrivateObjectKey: jest.fn() } as never;
    const audit = { log: jest.fn() } as never;
    const emitter = { emit: jest.fn() } as never;
    const env = loadAuthEnvRuntime(null as never);
    const sessionRevocation = { revokeAllForUser: jest.fn() } as never;
    const configService = {
      get: jest.fn((key: string) => (key === 'TERMS_VERSION' ? '1' : undefined)),
    } as unknown as ConfigService;
    const rotation = new RefreshTokenRotationService(
      prisma,
      audit as never,
      emitter as never,
      sessionRevocation,
      env,
      { get: jest.fn(), set: jest.fn() } as never,
    );
    const session = new AuthSessionService(
      prisma,
      jwt,
      uploads as never,
      sessionRevocation,
      env,
      configService,
      rotation,
    );
    await expect(session.refresh('nodotseparator')).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
