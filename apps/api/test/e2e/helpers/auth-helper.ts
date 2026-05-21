import type { INestApplication } from '@nestjs/common';
import request from 'supertest';

export function uniquePhone(): string {
  const n = String(1_000_000 + Math.floor(Math.random() * 8_999_999));
  return `+1555${n}`;
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

  const reg = await agent.post('/auth/register').send({
    firstName: 'E2e',
    lastName: 'User',
    email,
    phoneNumber,
    password,
  });
  expect([200, 201]).toContain(reg.status);
  expect(reg.body.requiresPhoneVerification).toBe(true);
  expect(reg.body.userId).toBeDefined();

  const sendOtp = await agent.post('/auth/otp/send').send({ phoneNumber });
  expect(sendOtp.status).toBe(200);
  const code =
    sendOtp.body.devCode ??
    (process.env.E2E_OTP_CODE as string | undefined);
  if (!code) {
    throw new Error('OTP devCode required for e2e verify (set SMS_PROVIDER!=twilio or E2E_OTP_CODE)');
  }

  const verified = await agent.post('/auth/otp/verify').send({ phoneNumber, code });
  expect(verified.status).toBe(200);
  expect(verified.body.accessToken).toBeDefined();

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
  const req = await agent.post('/auth/password-reset/request').send({ phoneNumber });
  expect(req.status).toBe(200);
  const code =
    req.body.devCode ?? (process.env.E2E_OTP_CODE as string | undefined);
  if (!code) {
    throw new Error(
      'password-reset devCode required (SMS_PROVIDER!=twilio or E2E_OTP_CODE)',
    );
  }

  await agent
    .post('/auth/password-reset/verify-code')
    .send({ phoneNumber, code })
    .expect(200);

  await agent
    .post('/auth/password-reset/confirm')
    .send({ phoneNumber, code, newPassword })
    .expect(200);

  return code;
}
