import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { apiPath } from './api-path';

export function uniquePhone(): string {
  const n = String(1_000_000 + Math.floor(Math.random() * 8_999_999));
  return `+1555${n}`;
}

/** Isolated throttle bucket per e2e flow (register, OTP, password-reset). */
export function e2eThrottleIp(): string {
  return `203.0.${Math.floor(Math.random() * 254) + 1}.${Math.floor(Math.random() * 254) + 1}`;
}

function withE2eIp(req: request.Test, ip: string): request.Test {
  return req.set('X-Forwarded-For', ip);
}

export type RegisteredCitizen = {
  accessToken: string;
  refreshToken: string;
  email: string;
  phoneNumber: string;
  password: string;
};

/** Registers a citizen and completes phone OTP verification to obtain tokens. */
export async function registerCitizen(
  app: INestApplication,
  label: string,
): Promise<RegisteredCitizen> {
  const password = 'E2eTest99!';
  const email = `e2e_${label}_${Date.now()}@test.local`;
  const phoneNumber = uniquePhone();
  const agent = request(app.getHttpServer());
  const throttleIp = e2eThrottleIp();

  const reg = await withE2eIp(agent.post(apiPath('/auth/register')), throttleIp).send({
    firstName: 'E2e',
    lastName: 'User',
    email,
    phoneNumber,
    password,
    termsAcceptedAt: new Date().toISOString(),
    termsVersion: '1',
  });
  expect([200, 201]).toContain(reg.status);
  expect(reg.body.requiresPhoneVerification).toBe(true);
  expect(reg.body.userId).toBeDefined();

  let code =
    reg.body.devCode ?? (process.env.E2E_OTP_CODE as string | undefined);
  if (!code) {
    const sendOtp = await withE2eIp(agent.post(apiPath('/auth/otp/send')), throttleIp).send({
      phoneNumber,
    });
    expect(sendOtp.status).toBe(200);
    code =
      sendOtp.body.devCode ?? (process.env.E2E_OTP_CODE as string | undefined);
  }
  if (!code) {
    throw new Error('OTP devCode required for e2e verify (set SMS_PROVIDER!=twilio or E2E_OTP_CODE)');
  }

  const verified = await withE2eIp(agent.post(apiPath('/auth/otp/verify')), throttleIp).send({
    phoneNumber,
    code,
  });
  expect(verified.status).toBe(200);
  expect(verified.body.accessToken).toBeDefined();
  expect(verified.body.user?.requiresTermsAcceptance).toBe(false);

  return {
    accessToken: verified.body.accessToken as string,
    refreshToken: verified.body.refreshToken as string,
    email,
    phoneNumber,
    password,
  };
}

/** SMS password-reset flow using devCode (CI: SMS_PROVIDER=none, NODE_ENV=test). */
export async function resetPasswordViaSms(
  app: INestApplication,
  phoneNumber: string,
  newPassword: string,
): Promise<string> {
  const agent = request(app.getHttpServer());
  const throttleIp = e2eThrottleIp();
  const req = await withE2eIp(agent.post(apiPath('/auth/password-reset/request')), throttleIp).send({
    phoneNumber,
  });
  expect(req.status).toBe(200);
  const code =
    req.body.devCode ?? (process.env.E2E_OTP_CODE as string | undefined);
  if (!code) {
    throw new Error(
      'password-reset devCode required (SMS_PROVIDER!=twilio or E2E_OTP_CODE)',
    );
  }

  await withE2eIp(agent.post(apiPath('/auth/password-reset/verify-code')), throttleIp)
    .send({ phoneNumber, code })
    .expect((res) => {
      expect([200, 204]).toContain(res.status);
    });

  await withE2eIp(agent.post(apiPath('/auth/password-reset/confirm')), throttleIp)
    .send({ phoneNumber, code, newPassword })
    .expect(200);

  return code;
}

/** Email password-reset flow using devCode (CI: SMS_PROVIDER=none, NODE_ENV=test). */
export async function resetPasswordViaEmail(
  app: INestApplication,
  email: string,
  newPassword: string,
): Promise<string> {
  const agent = request(app.getHttpServer());
  const throttleIp = e2eThrottleIp();
  const req = await withE2eIp(agent.post(apiPath('/auth/password-reset/request')), throttleIp).send({
    email,
  });
  expect(req.status).toBe(200);
  const code =
    req.body.devCode ?? (process.env.E2E_OTP_CODE as string | undefined);
  if (!code) {
    throw new Error(
      'password-reset devCode required (SMS_PROVIDER!=twilio or E2E_OTP_CODE)',
    );
  }

  await withE2eIp(agent.post(apiPath('/auth/password-reset/email/verify-code')), throttleIp)
    .send({ email, code })
    .expect(204);

  await withE2eIp(agent.post(apiPath('/auth/password-reset/email/confirm')), throttleIp)
    .send({ email, code, newPassword })
    .expect(200);

  return code;
}
