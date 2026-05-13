/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { uniquePhone } from './helpers/auth-helper';

describe('Validation errors (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
  });

  afterAll(async () => {
    await app.close();
  });

  it('rejects unknown properties on register (forbidNonWhitelisted)', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        firstName: 'E2e',
        lastName: 'User',
        email: `e2e_val_${Date.now()}@test.local`,
        phoneNumber: uniquePhone(),
        password: 'E2eTest99!',
        evilField: 'nope',
      })
      .expect(400);
    expect(res.body.code).toBe('VALIDATION_ERROR');
  });
});
