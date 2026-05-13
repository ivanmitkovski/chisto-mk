/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { deleteUsersByEmailPrefix } from './helpers/db-cleanup';
import { PrismaService } from '../../src/prisma/prisma.service';
import { registerCitizen } from './helpers/auth-helper';

describe('Auth session (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
    prisma = ctx.prisma;
  });

  afterAll(async () => {
    await deleteUsersByEmailPrefix(prisma, 'e2e_session_');
    await app.close();
  });

  it('register, login, refresh, logout', async () => {
    const u = await registerCitizen(app, 'session');
    const agent = request(app.getHttpServer());

    const refreshed = await agent
      .post('/auth/refresh')
      .send({ refreshToken: u.refreshToken })
      .expect(200);
    expect(refreshed.body.accessToken).toBeDefined();

    await agent.post('/auth/logout').send({ refreshToken: refreshed.body.refreshToken }).expect(204);
  });

  it('rejects reuse of revoked refresh token after rotation', async () => {
    const u = await registerCitizen(app, 'session_reuse');
    const agent = request(app.getHttpServer());
    const first = u.refreshToken;

    const rotated = await agent.post('/auth/refresh').send({ refreshToken: first }).expect(200);
    expect(rotated.body.refreshToken).toBeDefined();
    expect(rotated.body.refreshToken).not.toBe(first);

    const replay = await agent.post('/auth/refresh').send({ refreshToken: first });
    expect(replay.status).toBe(401);
    expect(replay.body?.code ?? replay.body?.message).toBeDefined();
  });
});
