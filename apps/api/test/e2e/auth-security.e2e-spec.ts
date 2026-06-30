/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import * as jwt from 'jsonwebtoken';
import request from 'supertest';
import { io as ioClient, type Socket } from 'socket.io-client';
import { createE2eApplication } from './helpers/bootstrap-app';
import { apiPath } from './helpers/api-path';
import { registerCitizen, e2eThrottleIp } from './helpers/auth-helper';
import { PrismaService } from '../../src/prisma/prisma.service';
import { Role } from '../../src/prisma-client';

describe('Auth security (integration)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
    prisma = ctx.prisma;
    await app.listen(0);
  });

  afterAll(async () => {
    await app.close();
  });

  it('rejects alg:none JWT', async () => {
    const header = Buffer.from(JSON.stringify({ alg: 'none', typ: 'JWT' })).toString('base64url');
    const payload = Buffer.from(JSON.stringify({ sub: 'x', role: Role.USER })).toString('base64url');
    const token = `${header}.${payload}.`;
    await request(app.getHttpServer())
      .get(apiPath('/auth/me'))
      .set('Authorization', `Bearer ${token}`)
      .expect(401);
  });

  it('rejects access token without sid', async () => {
    const secret = process.env.JWT_SECRET ?? 'ci_jwt_secret_must_be_at_least_thirty_two_chars';
    const token = jwt.sign({ sub: 'fake', role: Role.USER }, secret, {
      issuer: 'chisto-api',
      audience: 'chisto-api',
    });
    const res = await request(app.getHttpServer())
      .get(apiPath('/auth/me'))
      .set('Authorization', `Bearer ${token}`)
      .expect(401);
    expect(res.body.code).toBe('SESSION_REQUIRED');
  });

  it('returns INVALID_CREDENTIALS for wrong password without 500', async () => {
    const u = await registerCitizen(app, 'wrong_pwd_login');
    const throttleIp = e2eThrottleIp();
    const res = await request(app.getHttpServer())
      .post(apiPath('/auth/login'))
      .set('X-Forwarded-For', throttleIp)
      .send({ phoneNumber: u.phoneNumber, password: 'WrongPass1!' })
      .expect(401);

    expect(res.body.code).toBe('INVALID_CREDENTIALS');

    const failure = await prisma.loginFailure.findUnique({
      where: { phoneNumber: u.phoneNumber },
    });
    expect(failure).toBeTruthy();
    expect(failure!.attemptCount).toBeGreaterThanOrEqual(1);
  });

  it('refresh reuse revokes all sessions', async () => {
    const u = await registerCitizen(app, 'refresh_reuse');
    const agent = request(app.getHttpServer());
    const throttleIp = e2eThrottleIp();
    const login2 = await agent
      .post(apiPath('/auth/login'))
      .set('X-Forwarded-For', throttleIp)
      .send({ phoneNumber: u.phoneNumber, password: u.password, rememberMe: true })
      .expect(200);
    const oldRefresh = login2.body.refreshToken as string;

    await agent.post(apiPath('/auth/refresh')).send({ refreshToken: oldRefresh }).expect(200);
    await agent.post(apiPath('/auth/refresh')).send({ refreshToken: oldRefresh }).expect(401);

    const audit = await prisma.auditLog.findFirst({
      where: { actorId: { not: null }, action: 'SESSIONS_REVOKED_ALL' },
      orderBy: { createdAt: 'desc' },
    });
    expect(audit).toBeTruthy();
  });

  it('rejects WebSocket without sid in token', async () => {
    const secret = process.env.JWT_SECRET ?? 'ci_jwt_secret_must_be_at_least_thirty_two_chars';
    const token = jwt.sign({ sub: 'ws-user', role: Role.USER }, secret, {
      issuer: 'chisto-api',
      audience: 'chisto-api',
    });
    const port = (app.getHttpServer().address() as { port: number }).port;
    await new Promise<void>((resolve, reject) => {
      const socket: Socket = ioClient(`http://127.0.0.1:${port}/chat`, {
        auth: { token },
        transports: ['websocket'],
        forceNew: true,
        extraHeaders: { Origin: 'http://localhost:3000' },
      });
      const t = setTimeout(() => {
        socket.close();
        reject(new Error('WS did not reject in time'));
      }, 5000);
      const finish = (): void => {
        clearTimeout(t);
        socket.close();
        resolve();
      };
      socket.on('error', (payload: { code?: string }) => {
        if (
          payload?.code === 'SESSION_REQUIRED' ||
          payload?.code === 'AUTH_FAILED' ||
          payload?.code === 'INVALID_TOKEN'
        ) {
          finish();
        }
      });
      socket.on('connect_error', () => {
        finish();
      });
    });
  });
});
