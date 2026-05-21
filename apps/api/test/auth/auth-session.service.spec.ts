/// <reference types="jest" />

import { UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { AuthSessionService } from '../../src/auth/auth-session.service';
import { loadAuthEnvRuntime } from '../../src/auth/auth-env.config';

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
    const session = new AuthSessionService(
      prisma,
      jwt,
      uploads as never,
      audit as never,
      emitter as never,
      sessionRevocation,
      env,
      configService,
    );
    await expect(session.refresh('nodotseparator')).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
