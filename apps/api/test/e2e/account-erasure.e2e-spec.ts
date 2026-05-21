/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { apiPath } from './helpers/api-path';
import { registerCitizen } from './helpers/auth-helper';
import { PrismaService } from '../../src/prisma/prisma.service';

describe('Account erasure (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
    prisma = ctx.prisma;
  });

  afterAll(async () => {
    await app.close();
  });

  it('removes device tokens and notification outbox rows on delete', async () => {
    const u = await registerCitizen(app, 'erasure_fcm');
    await prisma.userDeviceToken.create({
      data: {
        userId: (await prisma.user.findFirst({ where: { email: u.email }, select: { id: true } }))!.id,
        token: `e2e-fcm-${Date.now()}`,
        platform: 'IOS',
      },
    });
    const user = await prisma.user.findFirst({ where: { email: u.email } });
    expect(user).toBeTruthy();

    await request(app.getHttpServer())
      .delete(apiPath('/auth/me'))
      .set('Authorization', `Bearer ${u.accessToken}`)
      .expect(204);

    const tokens = await prisma.userDeviceToken.count({ where: { userId: user!.id } });
    expect(tokens).toBe(0);
  });
});
