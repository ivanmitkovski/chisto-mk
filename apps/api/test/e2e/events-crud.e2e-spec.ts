/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { deleteUsersByEmailPrefix } from './helpers/db-cleanup';
import { registerCitizen } from './helpers/auth-helper';
import { PrismaService } from '../../src/prisma/prisma.service';

describe('Events list (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
    prisma = ctx.prisma;
  });

  afterAll(async () => {
    await deleteUsersByEmailPrefix(prisma, 'e2e_events_');
    await app.close();
  });

  it('GET /events returns paginated list for authenticated user', async () => {
    const u = await registerCitizen(app, 'events');
    const res = await request(app.getHttpServer())
      .get('/events')
      .set('Authorization', `Bearer ${u.accessToken}`)
      .query({ limit: 10 })
      .expect(200);
    expect(res.body).toBeDefined();
  });
});
