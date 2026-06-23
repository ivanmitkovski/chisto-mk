/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import * as jwt from 'jsonwebtoken';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { deleteUsersByEmailPrefix } from './helpers/db-cleanup';
import { PrismaService } from '../../src/prisma/prisma.service';
import { Role } from '../../src/prisma-client';

async function createAdminAccessToken(prisma: PrismaService): Promise<string> {
  const adminEmail = `e2e_active_users_admin_${Date.now()}@test.local`;
  const adminPhone = `+3897${String(Date.now()).slice(-7)}`;

  const adminUser = await prisma.user.create({
    data: {
      firstName: 'Admin',
      lastName: 'ActiveUsers',
      email: adminEmail,
      phoneNumber: adminPhone,
      passwordHash: '$2b$04$placeholderhashplaceholderhashpl',
      role: Role.ADMIN,
      isPhoneVerified: true,
      termsAcceptedAt: new Date(),
      termsVersion: '1',
    },
  });

  const session = await prisma.userSession.create({
    data: {
      userId: adminUser.id,
      tokenId: 'activeusersadminsess123456',
      refreshTokenHash: 'hash',
      expiresAt: new Date(Date.now() + 86400000),
    },
  });

  const secret = process.env.JWT_SECRET ?? 'ci_jwt_secret_must_be_at_least_thirty_two_chars';
  return jwt.sign(
    { sub: adminUser.id, role: Role.ADMIN, sid: session.id },
    secret,
    { expiresIn: 900, issuer: 'chisto-api', audience: 'chisto-api', header: { kid: 'default', alg: 'HS256' } },
  );
}

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
    await app.close();
  });

  it('returns summary, list with filters, and alert CRUD', async () => {
    const adminToken = await createAdminAccessToken(prisma);
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
