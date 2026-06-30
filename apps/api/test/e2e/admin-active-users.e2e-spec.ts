/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { deleteUsersByEmailPrefix } from './helpers/db-cleanup';
import { createE2eAdminAccessToken } from './helpers/admin-access-token';
import { PrismaService } from '../../src/prisma/prisma.service';

describe('Admin active users (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
    prisma = ctx.prisma;
  });

  afterAll(async () => {
    await deleteUsersByEmailPrefix(prisma, 'e2e_active_users_');
    await deleteUsersByEmailPrefix(prisma, 'e2e_admin');
    await app.close();
  });

  it('returns summary, list with filters, and alert CRUD', async () => {
    const { token: adminToken } = await createE2eAdminAccessToken(prisma, {
      emailPrefix: 'e2e_active_users_admin',
    });
    const server = app.getHttpServer();

    const summary = await request(server)
      .get('/v1/admin/active-users/summary')
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);
    expect(summary.body).toMatchObject({
      currentActive: expect.any(Number),
      online: expect.any(Number),
      away: expect.any(Number),
    });

    const list = await request(server)
      .get('/v1/admin/active-users?page=1&limit=10&status=online')
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);
    expect(Array.isArray(list.body.rows)).toBe(true);
    expect(list.body.total).toEqual(expect.any(Number));

    const created = await request(server)
      .post('/v1/admin/alert-rules')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        metric: 'CONCURRENT',
        comparator: 'GT',
        threshold: 9999,
        windowSeconds: 300,
      })
      .expect(201);

    const ruleId = created.body.id as string;
    expect(ruleId).toBeTruthy();

    await request(server)
      .patch(`/v1/admin/alert-rules/${ruleId}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ enabled: false })
      .expect(200);

    await request(server)
      .delete(`/v1/admin/alert-rules/${ruleId}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);
  });
});
