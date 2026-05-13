/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';

describe('Cluster Redis (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /health/ready returns redis ok when REDIS_URL is set (CI parity)', async () => {
    if (!process.env.REDIS_URL?.trim()) {
      console.warn('[e2e] Skipping Redis readiness assertion — REDIS_URL unset');
      return;
    }
    const res = await request(app.getHttpServer()).get('/health/ready').expect(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.redis).toBe('ok');
  });

  it('GET /health/ready returns s3 ok when bucket + MinIO-style endpoint are set', async () => {
    if (!process.env.S3_BUCKET_NAME?.trim() || !process.env.S3_ENDPOINT_URL?.trim()) {
      console.warn(
        '[e2e] Skipping S3 readiness assertion — set S3_BUCKET_NAME and S3_ENDPOINT_URL (see runbook §12)',
      );
      return;
    }
    const res = await request(app.getHttpServer()).get('/health/ready').expect(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.s3).toBe('ok');
  });
});
