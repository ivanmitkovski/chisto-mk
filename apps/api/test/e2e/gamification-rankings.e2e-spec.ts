/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { apiPath } from './helpers/api-path';
import { registerCitizen } from './helpers/auth-helper';

describe('Gamification rankings (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    ({ app } = await createE2eApplication());
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /gamification/rankings/weekly returns leaderboard payload', async () => {
    const u = await registerCitizen(app, 'rankings_weekly');
    const res = await request(app.getHttpServer())
      .get(apiPath('/gamification/rankings/weekly'))
      .set('Authorization', `Bearer ${u.accessToken}`)
      .expect(200);
    expect(res.body).toHaveProperty('entries');
    expect(Array.isArray(res.body.entries)).toBe(true);
  });
});
