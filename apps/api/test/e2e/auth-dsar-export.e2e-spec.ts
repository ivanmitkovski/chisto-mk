/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { apiPath } from './helpers/api-path';
import { registerCitizen } from './helpers/auth-helper';

describe('Auth DSAR export (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    ({ app } = await createE2eApplication());
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /auth/me/data-export returns JSON for authenticated user', async () => {
    const u = await registerCitizen(app, 'dsar_export');
    const res = await request(app.getHttpServer())
      .get(apiPath('/auth/me/data-export'))
      .set('Authorization', `Bearer ${u.accessToken}`)
      .expect(200);
    const lines = String(res.text)
      .trim()
      .split('\n')
      .filter(Boolean);
    expect(lines.length).toBeGreaterThan(0);
    const first = JSON.parse(lines[0]) as { section: string };
    expect(first.section).toBe('meta');
  });
});
