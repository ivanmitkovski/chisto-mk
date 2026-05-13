/// <reference types="jest" />

import { UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
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
    const session = new AuthSessionService(prisma, jwt, uploads as never, audit as never, emitter as never, env);
    await expect(session.refresh('nodotseparator')).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
