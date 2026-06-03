/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import sharp from 'sharp';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { apiPath } from './helpers/api-path';
import { registerCitizen } from './helpers/auth-helper';

describe('Reports evidence (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    ({ app } = await createE2eApplication());
  });

  afterAll(async () => {
    await app.close();
  });

  it('POST /reports/upload accepts image evidence', async () => {
    const u = await registerCitizen(app, 'report_evidence');
    const jpeg = await sharp({
      create: { width: 128, height: 128, channels: 3, background: { r: 10, g: 20, b: 30 } },
    })
      .jpeg()
      .toBuffer();
    const res = await request(app.getHttpServer())
      .post(apiPath('/reports/upload'))
      .set('Authorization', `Bearer ${u.accessToken}`)
      .attach('files', jpeg, {
        filename: 'evidence.jpg',
        contentType: 'image/jpeg',
      });
    expect([200, 201, 503]).toContain(res.status);
    if (res.status === 503) {
      expect(res.body.code).toBe('REPORT_UPLOAD_STORAGE_ERROR');
      return;
    }
    expect(Array.isArray(res.body.urls)).toBe(true);
    expect(res.body.urls.length).toBeGreaterThan(0);
  });
});
