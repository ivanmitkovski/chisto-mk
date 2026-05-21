/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { deleteUsersByEmailPrefix } from './helpers/db-cleanup';
import { PrismaService } from '../../src/prisma/prisma.service';
import { registerCitizen } from './helpers/auth-helper';

describe('Auth hardening (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
    prisma = ctx.prisma;
  });

  afterAll(async () => {
    await deleteUsersByEmailPrefix(prisma, 'e2e_hardening_');
    await app.close();
  });

  it('rejects login when phone is not verified', async () => {
    const email = `e2e_hardening_unverified_${Date.now()}@example.com`;
    const phone = `+38970${String(Date.now()).slice(-7)}`;
    await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        firstName: 'E2E',
        lastName: 'Unverified',
        email,
        phoneNumber: phone,
        password: 'Password1',
      })
      .expect(201);

    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ phoneNumber: phone, password: 'Password1' })
      .expect(401);

    expect(login.body.code).toBe('PHONE_NOT_VERIFIED');
  });

  it('saves home location after registration', async () => {
    const u = await registerCitizen(app, 'hardening_home');
    const agent = request(app.getHttpServer());

    await agent
      .patch('/auth/me/home-location')
      .set('Authorization', `Bearer ${u.accessToken}`)
      .send({
        latitude: 41.9981,
        longitude: 21.4254,
        label: 'Skopje',
      })
      .expect(200);

    const me = await agent
      .get('/auth/me')
      .set('Authorization', `Bearer ${u.accessToken}`)
      .expect(200);

    expect(me.body.homeLatitude).toBeCloseTo(41.9981, 4);
    expect(me.body.homeLongitude).toBeCloseTo(21.4254, 4);
    expect(me.body.homeLocationLabel).toBe('Skopje');
  });
});
