/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import * as jwt from 'jsonwebtoken';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { deleteUsersByEmailPrefix } from './helpers/db-cleanup';
import { uniquePhone } from './helpers/auth-helper';
import { PrismaService } from '../../src/prisma/prisma.service';
import { Role } from '../../src/prisma-client';

async function createAdminAccessToken(prisma: PrismaService): Promise<{ token: string; userId: string }> {
  const adminEmail = `e2e_broadcast_admin_${Date.now()}@test.local`;
  const adminPhone = uniquePhone();

  const adminUser = await prisma.user.create({
    data: {
      firstName: 'Admin',
      lastName: 'Broadcast',
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
      tokenId: 'admbrdcast1234567890',
      refreshTokenHash: 'hash',
      expiresAt: new Date(Date.now() + 86400000),
    },
  });

  const secret = process.env.JWT_SECRET ?? 'ci_jwt_secret_must_be_at_least_thirty_two_chars';
  const token = jwt.sign(
    { sub: adminUser.id, role: Role.ADMIN, sid: session.id },
    secret,
    { expiresIn: 900, issuer: 'chisto-api', audience: 'chisto-api', header: { kid: 'default', alg: 'HS256' } },
  );

  return { token, userId: adminUser.id };
}

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
    await app.close();
  });

  it('POST /admin/broadcasts/audience-preview returns recipient count', async () => {
    const { token } = await createAdminAccessToken(prisma);
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
    const { token, userId } = await createAdminAccessToken(prisma);
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
          lastName: 'Broadcast',
          status: 'ACTIVE',
        }),
      ]),
    );
  });
});
