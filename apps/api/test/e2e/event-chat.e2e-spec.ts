/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { deleteUsersByEmailPrefix } from './helpers/db-cleanup';
import { registerCitizen } from './helpers/auth-helper';
import { PrismaService } from '../../src/prisma/prisma.service';

const FAKE_EVENT_CUID = 'clq5j8m9k0000e2etestval01';

describe('Event chat (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
    prisma = ctx.prisma;
  });

  afterAll(async () => {
    await deleteUsersByEmailPrefix(prisma, 'e2e_chat_');
    await app.close();
  });

  it('list messages returns 401 without bearer token', async () => {
    await request(app.getHttpServer()).get(`/events/${FAKE_EVENT_CUID}/chat`).expect(401);
  });

  it('list messages returns structured response for unknown event when authenticated', async () => {
    const u = await registerCitizen(app, 'chat');
    const res = await request(app.getHttpServer())
      .get(`/events/${FAKE_EVENT_CUID}/chat`)
      .set('Authorization', `Bearer ${u.accessToken}`);
    expect([401, 403, 404]).toContain(res.status);
  });
});
