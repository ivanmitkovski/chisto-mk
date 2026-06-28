/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { deleteUsersByEmailPrefix } from './helpers/db-cleanup';
import { registerCitizen } from './helpers/auth-helper';
import { createE2eAdminAccessToken } from './helpers/admin-access-token';
import { PrismaService } from '../../src/prisma/prisma.service';
import { UserStatus } from '../../src/prisma-client';

describe('Admin users (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
    prisma = ctx.prisma;
  });

  afterAll(async () => {
    await deleteUsersByEmailPrefix(prisma, 'e2e_users_');
    await deleteUsersByEmailPrefix(prisma, 'e2e_admin');
    await app.close();
  });

  it('lists users, loads detail, suspends with reason, and revokes sessions', async () => {
    const { token: adminToken } = await createE2eAdminAccessToken(prisma, { emailPrefix: 'e2e_users_admin' });
    const citizen = await registerCitizen(app, 'users_flow');
    const targetUser = await prisma.user.findUniqueOrThrow({ where: { email: citizen.email } });
    const server = app.getHttpServer();

    const list = await request(server)
      .get('/v1/admin/users?page=1&limit=20')
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);
    expect(Array.isArray(list.body.data)).toBe(true);
    expect(list.body.meta).toMatchObject({
      page: 1,
      limit: 20,
      total: expect.any(Number),
    });

    const detail = await request(server)
      .get(`/v1/admin/users/${targetUser.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);
    expect(detail.body.id).toBe(targetUser.id);
    expect(detail.body.status).toBe(UserStatus.ACTIVE);

    const activeSessionsBefore = await prisma.userSession.count({
      where: { userId: targetUser.id, revokedAt: null },
    });
    expect(activeSessionsBefore).toBeGreaterThan(0);

    await request(server)
      .patch(`/v1/admin/users/${targetUser.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ status: UserStatus.SUSPENDED, reasonCode: 'spam', note: 'e2e suspend' })
      .expect(200);

    const suspended = await request(server)
      .get(`/v1/admin/users/${targetUser.id}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);
    expect(suspended.body.status).toBe(UserStatus.SUSPENDED);

    const activeSessionsAfter = await prisma.userSession.count({
      where: { userId: targetUser.id, revokedAt: null },
    });
    expect(activeSessionsAfter).toBe(0);

    const history = await request(server)
      .get(`/v1/admin/users/${targetUser.id}/status-history`)
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);
    expect(history.body.data.length).toBeGreaterThan(0);
    expect(history.body.data[0]).toMatchObject({
      toStatus: UserStatus.SUSPENDED,
      reasonCode: 'spam',
    });

    const dataExport = await request(server)
      .get(`/v1/admin/users/${targetUser.id}/data-export`)
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200);
    expect(dataExport.body).toMatchObject({
      profile: expect.objectContaining({ id: targetUser.id }),
    });
  });

  it('changes email via admin-assisted OTP flow when dev code is returned', async () => {
    if (process.env.AUTH_RETURN_DEV_CODE !== 'true' && process.env.NODE_ENV !== 'test') {
      return;
    }

    const { token: adminToken } = await createE2eAdminAccessToken(prisma, { emailPrefix: 'e2e_users_admin' });
    const citizen = await registerCitizen(app, 'users_email');
    const targetUser = await prisma.user.findUniqueOrThrow({ where: { email: citizen.email } });
    const server = app.getHttpServer();
    const newEmail = `e2e_users_email_new_${Date.now()}@test.local`;

    const requestRes = await request(server)
      .post(`/v1/admin/users/${targetUser.id}/email/change-request`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ newEmail, reasonCode: 'user_request', note: 'e2e email change' })
      .expect(201);

    const devCode = requestRes.body.devCode as string | undefined;
    if (!devCode) {
      return;
    }

    await request(server)
      .post(`/v1/admin/users/${targetUser.id}/email/confirm`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ newEmail, code: devCode })
      .expect(201);

    const updated = await prisma.user.findUniqueOrThrow({ where: { id: targetUser.id } });
    expect(updated.email).toBe(newEmail);

    const activeSessionsAfter = await prisma.userSession.count({
      where: { userId: targetUser.id, revokedAt: null },
    });
    expect(activeSessionsAfter).toBe(0);
  });
});
