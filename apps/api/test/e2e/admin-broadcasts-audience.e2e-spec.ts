/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { deleteUsersByEmailPrefix } from './helpers/db-cleanup';
import { createE2eAdminAccessToken } from './helpers/admin-access-token';
import { PrismaService } from '../../src/prisma/prisma.service';

describe('Admin broadcasts audience (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
    prisma = ctx.prisma;
  });

  afterAll(async () => {
    await deleteUsersByEmailPrefix(prisma, 'e2e_broadcast_admin_');
    await deleteUsersByEmailPrefix(prisma, 'e2e_admin');
    await app.close();
  });

  it('POST /admin/broadcasts/audience-preview returns recipient count', async () => {
    const { token } = await createE2eAdminAccessToken(prisma, { emailPrefix: 'e2e_broadcast_admin' });
    const server = app.getHttpServer();

    const res = await request(server)
      .post('/v1/admin/broadcasts/audience-preview')
      .set('Authorization', `Bearer ${token}`)
      .send({ audience: 'all' })
      .expect(201);

    expect(res.body).toMatchObject({
      recipientCount: expect.any(Number),
      capped: expect.any(Boolean),
      cap: 5000,
    });
  });

  it('POST /admin/broadcasts/audience-users/lookup returns user rows', async () => {
    const { token, userId } = await createE2eAdminAccessToken(prisma, { emailPrefix: 'e2e_broadcast_admin' });
    const server = app.getHttpServer();

    const res = await request(server)
      .post('/v1/admin/broadcasts/audience-users/lookup')
      .set('Authorization', `Bearer ${token}`)
      .send({ userIds: [userId] })
      .expect(201);

    expect(res.body.users).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          id: userId,
          firstName: 'Admin',
          lastName: 'E2E',
          status: 'ACTIVE',
        }),
      ]),
    );
  });
});
