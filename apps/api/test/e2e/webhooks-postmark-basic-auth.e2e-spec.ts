/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';

describe('Postmark webhook Basic Auth (e2e)', () => {
  let app: INestApplication;
  const user = 'postmark_webhook_user';
  const pass = 'postmark_webhook_pass_test_value';

  beforeAll(async () => {
    process.env.POSTMARK_WEBHOOK_BASIC_USER = user;
    process.env.POSTMARK_WEBHOOK_BASIC_PASS = pass;
    const ctx = await createE2eApplication();
    app = ctx.app;
  });

  afterAll(async () => {
    delete process.env.POSTMARK_WEBHOOK_BASIC_USER;
    delete process.env.POSTMARK_WEBHOOK_BASIC_PASS;
    await app.close();
  });

  function authHeader(): string {
    return `Basic ${Buffer.from(`${user}:${pass}`).toString('base64')}`;
  }

  it('rejects missing auth', async () => {
    await request(app.getHttpServer())
      .post('/v1/webhooks/postmark')
      .send({
        RecordType: 'HardBounce',
        Email: 'bounced@example.com',
      })
      .expect(401);
  });

  it('accepts valid Basic Auth', async () => {
    await request(app.getHttpServer())
      .post('/v1/webhooks/postmark')
      .set('Authorization', authHeader())
      .send({
        RecordType: 'HardBounce',
        Email: 'bounced@example.com',
      })
      .expect(200)
      .expect({ ok: true });
  });
});
