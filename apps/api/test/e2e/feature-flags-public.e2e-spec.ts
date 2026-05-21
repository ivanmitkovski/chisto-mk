/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';

describe('Public feature flags (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /config/feature-flags returns a flags object', async () => {
    const res = await request(app.getHttpServer()).get('/config/feature-flags').expect(200);
    expect(res.body.flags).toBeDefined();
    expect(typeof res.body.flags).toBe('object');
  });
});
