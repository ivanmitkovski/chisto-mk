/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { apiPath } from './helpers/api-path';
import { registerCitizen } from './helpers/auth-helper';
import { DevicePlatform } from '../../src/prisma-client';

describe('Notifications inbox (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    ({ app } = await createE2eApplication());
  });

  afterAll(async () => {
    await app.close();
  });

  it('lists inbox and registers a device token', async () => {
    const u = await registerCitizen(app, 'notif_inbox');

    const list = await request(app.getHttpServer())
      .get(apiPath('/notifications'))
      .set('Authorization', `Bearer ${u.accessToken}`)
      .query({ page: 1, limit: 10 })
      .expect(200);
    expect(list.body).toHaveProperty('data');
    expect(list.body).toHaveProperty('meta');

    await request(app.getHttpServer())
      .post(apiPath('/notifications/devices'))
      .set('Authorization', `Bearer ${u.accessToken}`)
      .set('X-Idempotency-Key', `e2e-device-${Date.now()}`)
      .send({
        token: `e2e-fcm-${Date.now()}`,
        platform: DevicePlatform.IOS,
      })
      .expect((res) => {
        if (![200, 201].includes(res.status)) {
          throw new Error(`unexpected status ${res.status}`);
        }
      });
  });
});
