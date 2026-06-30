/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import * as jwt from 'jsonwebtoken';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { deleteUsersByEmailPrefix } from './helpers/db-cleanup';
import { createE2eAdminAccessToken } from './helpers/admin-access-token';
import { PrismaService } from '../../src/prisma/prisma.service';
import { registerCitizen, e2eThrottleIp, uniquePhone } from './helpers/auth-helper';
import { Role } from '../../src/prisma-client';

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
    await deleteUsersByEmailPrefix(prisma, 'e2e_admin');
    await app.close();
  });

  it('rejects access token without sid', async () => {
    const secret = process.env.JWT_SECRET ?? 'ci_jwt_secret_must_be_at_least_thirty_two_chars';
    const token = jwt.sign(
      { sub: 'fake-user', role: Role.USER },
      secret,
      { expiresIn: 60, issuer: 'chisto-api', audience: 'chisto-api' },
    );
    const res = await request(app.getHttpServer())
      .get('/v1/auth/me')
      .set('Authorization', `Bearer ${token}`)
      .expect(401);
    expect(res.body.code).toBe('SESSION_REQUIRED');
  });

  it('rejects demoted admin on next request', async () => {
    const { token: accessToken, userId } = await createE2eAdminAccessToken(prisma, {
      emailPrefix: 'e2e_hardening_admin',
    });

    await prisma.user.update({
      where: { id: userId },
      data: { role: Role.USER },
    });

    const adminRoute = await request(app.getHttpServer())
      .get('/v1/admin/overview')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(403);
    expect(adminRoute.body.code).toMatch(/FORBIDDEN|INSUFFICIENT_ROLE|UNAUTHORIZED/);
  });

  it('password change revokes other sessions', async () => {
    const u = await registerCitizen(app, 'pwd_revoke');
    const agent = request(app.getHttpServer());

    const login2 = await agent
      .post('/v1/auth/login')
      .set('X-Forwarded-For', e2eThrottleIp())
      .send({ phoneNumber: u.phoneNumber, password: u.password, rememberMe: true })
      .expect(200);

    await agent
      .patch('/v1/auth/me/password')
      .set('Authorization', `Bearer ${u.accessToken}`)
      .send({ currentPassword: u.password, newPassword: 'NewE2ePass99!' })
      .expect((res) => {
        expect([200, 204]).toContain(res.status);
      });

    await agent
      .post('/v1/auth/refresh')
      .send({ refreshToken: login2.body.refreshToken })
      .expect(401);
  });

  it('rejects login when phone is not verified', async () => {
    const email = `e2e_hardening_unverified_${Date.now()}@example.com`;
    const phone = uniquePhone();
    const throttleIp = e2eThrottleIp();
    await request(app.getHttpServer())
      .post('/v1/auth/register')
      .set('X-Forwarded-For', throttleIp)
      .send({
        firstName: 'E2E',
        lastName: 'Unverified',
        email,
        phoneNumber: phone,
        password: 'E2eTest99!',
        termsAcceptedAt: new Date().toISOString(),
        termsVersion: '1',
      })
      .expect((res) => {
        expect([200, 201]).toContain(res.status);
      });

    const login = await request(app.getHttpServer())
      .post('/v1/auth/login')
      .set('X-Forwarded-For', throttleIp)
      .send({ phoneNumber: phone, password: 'E2eTest99!' })
      .expect(401);

    expect(login.body.code).toBe('PHONE_NOT_VERIFIED');
  });

  it('exposes terms consent on /auth/me and accept-terms', async () => {
    const u = await registerCitizen(app, 'terms_consent');
    const agent = request(app.getHttpServer());

    const me = await agent
      .get('/v1/auth/me')
      .set('Authorization', `Bearer ${u.accessToken}`)
      .expect(200);
    expect(me.body.requiresTermsAcceptance).toBe(false);
    expect(me.body.termsVersion).toBe('1');
    expect(me.body.termsAcceptedAt).toBeDefined();

    await agent
      .post('/v1/auth/me/accept-terms')
      .set('Authorization', `Bearer ${u.accessToken}`)
      .send({ termsVersion: '1' })
      .expect(200);
  });

  it('saves home location after registration', async () => {
    const u = await registerCitizen(app, 'hardening_home');
    const agent = request(app.getHttpServer());

    await agent
      .patch('/v1/auth/me/home-location')
      .set('Authorization', `Bearer ${u.accessToken}`)
      .send({
        latitude: 41.9981,
        longitude: 21.4254,
        label: 'Skopje',
      })
      .expect(200);

    const me = await agent
      .get('/v1/auth/me')
      .set('Authorization', `Bearer ${u.accessToken}`)
      .expect(200);

    expect(me.body.homeLatitude).toBeCloseTo(41.9981, 4);
    expect(me.body.homeLongitude).toBeCloseTo(21.4254, 4);
    expect(me.body.homeLocationLabel).toBe('Skopje');
  });
});
