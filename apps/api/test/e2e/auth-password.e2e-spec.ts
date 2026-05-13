/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';

describe('Auth password (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
  });

  afterAll(async () => {
    await app.close();
  });

  it('password-reset request validates phone format', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/password-reset/request')
      .send({ phoneNumber: 'invalid' })
      .expect(400);
    expect(res.body.code).toBeDefined();
  });
});
