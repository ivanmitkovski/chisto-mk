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
  expect(reg.body.accessToken).toBeDefined();
  const login = await agent.post('/auth/login').send({ phoneNumber, password }).expect(200);
  const body = login.body as { accessToken: string; refreshToken: string };
  return {
    accessToken: body.accessToken,
    refreshToken: body.refreshToken,
    email,
    phoneNumber,
    password,
  };
}
