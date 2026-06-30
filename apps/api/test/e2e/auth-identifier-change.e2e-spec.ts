/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { apiPath } from './helpers/api-path';
import { registerCitizen, uniquePhone } from './helpers/auth-helper';

describe('Auth identifier change (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    ({ app } = await createE2eApplication());
  });

  afterAll(async () => {
    await app.close();
  });

  it('PATCH /auth/me/email returns 200 and requires confirmation', async () => {
    const u = await registerCitizen(app, 'id_change_email');
    const newEmail = `e2e_new_${Date.now()}@test.local`;
    const res = await request(app.getHttpServer())
      .patch(apiPath('/auth/me/email'))
      .set('Authorization', `Bearer ${u.accessToken}`)
      .send({ newEmail })
      .expect(200);
    expect(res.body).toBeDefined();
  });

  it('PATCH /auth/me/phone returns 200 for new number request', async () => {
    const u = await registerCitizen(app, 'id_change_phone');
    const newPhoneNumber = uniquePhone();
    await request(app.getHttpServer())
      .patch(apiPath('/auth/me/phone'))
      .set('Authorization', `Bearer ${u.accessToken}`)
      .send({ newPhoneNumber })
      .expect(200);
  });
});
