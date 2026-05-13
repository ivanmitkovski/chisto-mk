/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { uniquePhone } from './helpers/auth-helper';

describe('HTTP throttling (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
  });

  afterAll(async () => {
    await app.close();
  });

  it('returns 429 after exceeding register rate limit for the same IP', async () => {
    const agent = request(app.getHttpServer());
    const password = 'E2eThrottle99!';
    let lastStatus = 200;
    for (let i = 0; i < 6; i += 1) {
      const res = await agent.post('/auth/register').send({
        firstName: 'E2e',
        lastName: 'Throttle',
        email: `e2e_throttle_${Date.now()}_${i}@test.local`,
        phoneNumber: uniquePhone(),
        password,
      });
      lastStatus = res.status;
      if (res.status === 429) {
        expect(res.status).toBe(429);
        return;
      }
    }
    expect(lastStatus).toBe(429);
  });
});
