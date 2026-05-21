/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
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
    const res = await request(app.getHttpServer())
      .post(apiPath('/reports/upload'))
      .set('Authorization', `Bearer ${u.accessToken}`)
      .attach('files', Buffer.from('fakejpeg'), {
        filename: 'evidence.jpg',
        contentType: 'image/jpeg',
      });
    expect([200, 201]).toContain(res.status);
    expect(Array.isArray(res.body)).toBe(true);
  });
});
