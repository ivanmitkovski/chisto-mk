/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { deleteUsersByEmailPrefix } from './helpers/db-cleanup';
import { registerCitizen } from './helpers/auth-helper';
import { PrismaService } from '../../src/prisma/prisma.service';

const FAKE_EVENT_CUID = 'clq5j8m9k0000e2etestval00';

describe('Events participation (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
    prisma = ctx.prisma;
  });

  afterAll(async () => {
    await deleteUsersByEmailPrefix(prisma, 'e2e_partic_');
    await app.close();
  });

  it('POST join returns structured error for missing event', async () => {
    const u = await registerCitizen(app, 'partic');
    const res = await request(app.getHttpServer())
      .post(`/events/${FAKE_EVENT_CUID}/join`)
      .set('Authorization', `Bearer ${u.accessToken}`)
      .expect(404);
    expect(res.body.code).toBeDefined();
  });
});
