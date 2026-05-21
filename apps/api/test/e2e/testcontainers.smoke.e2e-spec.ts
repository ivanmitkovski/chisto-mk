/// <reference types="jest" />

import { startTestcontainers, stopTestcontainers } from './testcontainers.harness';
import { createE2eApplication } from './helpers/bootstrap-app';
import request from 'supertest';

const useTc = process.env.E2E_USE_TESTCONTAINERS === '1';

(useTc ? describe : describe.skip)('API testcontainers smoke', () => {
  beforeAll(async () => {
    await startTestcontainers();
  }, 120_000);

  afterAll(async () => {
    await stopTestcontainers();
  });

  it('GET /health returns 200', async () => {
    const { app } = await createE2eApplication();
    try {
      const res = await request(app.getHttpServer()).get('/health').expect(200);
      expect(res.body.status).toBe('ok');
    } finally {
      await app.close();
    }
  });
});
