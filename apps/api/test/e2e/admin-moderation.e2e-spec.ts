/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { deleteUsersByEmailPrefix } from './helpers/db-cleanup';
import { registerCitizen } from './helpers/auth-helper';
import { createE2eAdminAccessToken } from './helpers/admin-access-token';
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
    await deleteUsersByEmailPrefix(prisma, 'e2e_admin');
    await app.close();
  });

  it('GET /admin/overview forbids citizen role', async () => {
    const u = await registerCitizen(app, 'admin');
    const res = await request(app.getHttpServer())
      .get('/v1/admin/overview')
      .set('Authorization', `Bearer ${u.accessToken}`)
      .expect(403);
    expect(res.body.code).toBeDefined();
  });

  it('routes admin report moderation endpoints before citizen GET /reports/:id', async () => {
    const { token: adminToken } = await createE2eAdminAccessToken(prisma);
    const citizen = await registerCitizen(app, 'admin_reports_route');
    const server = app.getHttpServer();

    const queueSummary = await request(server)
      .get('/v1/reports/queue-summary')
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);
    expect(typeof queueSummary.body.total).toBe('number');

    const duplicates = await request(server)
      .get('/v1/reports/duplicates')
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);
    expect(Array.isArray(duplicates.body.data)).toBe(true);
    expect(duplicates.body.meta).toMatchObject({
      page: expect.any(Number),
      limit: expect.any(Number),
      total: expect.any(Number),
    });

    const list = await request(server)
      .get('/v1/reports?page=1&limit=20')
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);
    expect(Array.isArray(list.body.data)).toBe(true);
    expect(list.body.meta).toMatchObject({
      page: 1,
      limit: 20,
      total: expect.any(Number),
    });

    const citizenQueueSummary = await request(server)
      .get('/v1/reports/queue-summary')
      .set('Authorization', `Bearer ${citizen.accessToken}`)
      .expect(403);
    expect(citizenQueueSummary.body.code).toBeDefined();
    expect(citizenQueueSummary.body.code).not.toBe('INVALID_CUID');

    const missingReport = await request(server)
      .get('/v1/reports/cm1234567890abcdefghijkl')
      .set('Authorization', `Bearer ${citizen.accessToken}`)
      .expect(404);
    expect(missingReport.body.code).toBeDefined();
    expect(missingReport.body.code).not.toBe('INVALID_CUID');
  });
});
