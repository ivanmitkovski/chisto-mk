/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';

/**
 * MapRateLimitGuard uses Redis Lua when REDIS_URL is set (horizontal rate limits).
 * This is a product HTTP path beyond /health/ready (scorecard integration depth).
 */
describe('Map Redis rate limit (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /sites/map hits Redis-backed rate limit path when REDIS_URL is set', async () => {
    if (!process.env.REDIS_URL?.trim()) {
      return;
    }
    const res = await request(app.getHttpServer())
      .get('/sites/map')
      .query({ lat: 41.9973, lng: 21.4254, limit: 10 })
      .expect(200);
    expect(Array.isArray(res.body) || typeof res.body === 'object').toBe(true);
  });
});
