/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { deleteUsersByEmailPrefix } from './helpers/db-cleanup';
import {
  registerCitizen,
  resetPasswordViaEmail,
  resetPasswordViaSms,
  uniquePhone,
  e2eThrottleIp,
} from './helpers/auth-helper';
import { PrismaService } from '../../src/prisma/prisma.service';
import { LOGIN_MAX_ATTEMPTS } from '../../src/auth/constants/auth.constants';

describe('Auth password reset (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
    prisma = ctx.prisma;
    await prisma.featureFlag.upsert({
      where: { key: 'email_enabled' },
      create: { key: 'email_enabled', enabled: true },
      update: { enabled: true },
    });
  });

  afterAll(async () => {
    await deleteUsersByEmailPrefix(prisma, 'e2e_pwd_reset_');
    await app.close();
  });

  it('completes SMS reset, revokes old sessions, and allows login with new password', async () => {
    const u = await registerCitizen(app, 'pwd_reset_sms');
    const newPassword = 'NewE2ePass1!';
    const oldRefresh = u.refreshToken;

    await resetPasswordViaSms(app, u.phoneNumber, newPassword);

    await request(app.getHttpServer())
      .post('/v1/auth/login')
      .send({ phoneNumber: u.phoneNumber, password: u.password })
      .expect(401);

    const login = await request(app.getHttpServer())
      .post('/v1/auth/login')
      .send({ phoneNumber: u.phoneNumber, password: newPassword })
      .expect(200);
    expect(login.body.accessToken).toBeDefined();

    await request(app.getHttpServer())
      .post('/v1/auth/refresh')
      .send({ refreshToken: oldRefresh })
      .expect(401);
  });

  it('returns generic response for unknown phone without devCode', async () => {
    const res = await request(app.getHttpServer())
      .post('/v1/auth/password-reset/request')
      .send({ phoneNumber: uniquePhone() })
      .expect(200);
    expect(res.body.message).toContain('If an account exists');
    expect(res.body.devCode).toBeUndefined();
    expect(res.body.channel).toBeUndefined();
  });

  it('rejects wrong OTP on confirm', async () => {
    const u = await registerCitizen(app, 'pwd_reset_bad_otp');
    const req = await request(app.getHttpServer())
      .post('/v1/auth/password-reset/request')
      .send({ phoneNumber: u.phoneNumber });
    expect(req.status).toBe(200);
    expect(req.body.devCode).toBeDefined();

    await request(app.getHttpServer())
      .post('/v1/auth/password-reset/confirm')
      .send({
        phoneNumber: u.phoneNumber,
        code: '000000',
        newPassword: 'WrongOtpP1!',
      })
      .expect(401);
  });

  it('confirms email reset with code and logs in', async () => {
    const u = await registerCitizen(app, 'pwd_reset_email');
    const newPassword = 'EmailReset1!';

    await resetPasswordViaEmail(app, u.email, newPassword);

    await request(app.getHttpServer())
      .post('/v1/auth/login')
      .send({ phoneNumber: u.phoneNumber, password: newPassword })
      .expect(200);
  });

  it('returns identical generic response for unknown email on request', async () => {
    const res = await request(app.getHttpServer())
      .post('/v1/auth/password-reset/request')
      .set('X-Forwarded-For', e2eThrottleIp())
      .send({ email: `nobody_${Date.now()}@test.local` })
      .expect(200);
    expect(res.body.message).toContain('If an account exists');
    expect(res.body.channel).toBeUndefined();
    expect(res.body.devCode).toBeUndefined();
  });

  it('returns generic response for known email without revealing channel', async () => {
    const u = await registerCitizen(app, 'pwd_reset_email_req');
    const res = await request(app.getHttpServer())
      .post('/v1/auth/password-reset/request')
      .set('X-Forwarded-For', e2eThrottleIp())
      .send({ email: u.email })
      .expect(200);
    expect(res.body.message).toContain('If an account exists');
    expect(res.body.channel).toBeUndefined();
  });

  it('locks out citizen login after max failed attempts', async () => {
    const u = await registerCitizen(app, 'pwd_reset_lockout');
    const server = app.getHttpServer();
    const lockoutIp = e2eThrottleIp();

    for (let i = 0; i < LOGIN_MAX_ATTEMPTS; i++) {
      await request(server)
        .post('/v1/auth/login')
        .set('X-Forwarded-For', lockoutIp)
        .send({ phoneNumber: u.phoneNumber, password: 'WrongPass1!' })
        .expect(401);
    }

    const locked = await request(server)
      .post('/v1/auth/login')
      .set('X-Forwarded-For', lockoutIp)
      .send({ phoneNumber: u.phoneNumber, password: 'WrongPass1!' })
      .expect(401);
    expect(locked.body.code).toBe('TOO_MANY_ATTEMPTS');
    expect(locked.body.retryAfterSeconds).toBeGreaterThan(0);

    const newPassword = 'LockoutClear1!';
    await resetPasswordViaSms(app, u.phoneNumber, newPassword);

    await request(server)
      .post('/v1/auth/login')
      .set('X-Forwarded-For', e2eThrottleIp())
      .send({ phoneNumber: u.phoneNumber, password: newPassword })
      .expect(200);
  });

  it('blocks report submit when phone is not verified', async () => {
    const u = await registerCitizen(app, 'pwd_reset_guard');
    await prisma.user.update({
      where: { email: u.email },
      data: { isPhoneVerified: false },
    });

    const res = await request(app.getHttpServer())
      .post('/v1/reports')
      .set('Authorization', `Bearer ${u.accessToken}`)
      .send({
        latitude: 41.9981,
        longitude: 21.4254,
        title: `E2E guard ${Date.now()}`,
        category: 'OTHER',
      })
      .expect(403);

    expect(res.body.code).toBe('PHONE_NOT_VERIFIED');
  });

  it('changes password when authenticated with correct current password', async () => {
    const u = await registerCitizen(app, 'pwd_change_ok');
    const newPassword = 'ChangedPass1!';

    await request(app.getHttpServer())
      .patch('/v1/auth/me/password')
      .set('Authorization', `Bearer ${u.accessToken}`)
      .send({ currentPassword: u.password, newPassword })
      .expect((res) => {
        expect([200, 204]).toContain(res.status);
      });

    await request(app.getHttpServer())
      .post('/v1/auth/login')
      .set('X-Forwarded-For', e2eThrottleIp())
      .send({ phoneNumber: u.phoneNumber, password: newPassword })
      .expect(200);
  });

  it('rejects change password with wrong current password', async () => {
    const u = await registerCitizen(app, 'pwd_change_bad');
    const res = await request(app.getHttpServer())
      .patch('/v1/auth/me/password')
      .set('Authorization', `Bearer ${u.accessToken}`)
      .send({ currentPassword: 'WrongPass1!', newPassword: 'NewPass123!' })
      .expect(401);
    expect(res.body.code).toBeDefined();
  });
});
