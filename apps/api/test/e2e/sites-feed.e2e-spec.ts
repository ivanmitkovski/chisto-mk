/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';

describe('Sites feed (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /sites returns feed payload', async () => {
    const res = await request(app.getHttpServer()).get('/sites').query({ page: 1, limit: 5 }).expect(200);
    expect(res.body).toBeDefined();
  });
});
