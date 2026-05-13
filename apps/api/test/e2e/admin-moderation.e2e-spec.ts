/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { deleteUsersByEmailPrefix } from './helpers/db-cleanup';
import { registerCitizen } from './helpers/auth-helper';
import { PrismaService } from '../../src/prisma/prisma.service';

describe('Admin moderation (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
    prisma = ctx.prisma;
  });

  afterAll(async () => {
    await deleteUsersByEmailPrefix(prisma, 'e2e_admin_');
    await app.close();
  });

  it('GET /admin/overview forbids citizen role', async () => {
    const u = await registerCitizen(app, 'admin');
    const res = await request(app.getHttpServer())
      .get('/admin/overview')
      .set('Authorization', `Bearer ${u.accessToken}`)
      .expect(403);
    expect(res.body.code).toBeDefined();
  });
});
