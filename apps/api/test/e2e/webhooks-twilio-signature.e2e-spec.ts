/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import twilio from 'twilio';
import { createE2eApplication } from './helpers/bootstrap-app';

describe('Twilio webhook signature (e2e)', () => {
  let app: INestApplication;
  const authToken = 'e2e_twilio_auth_token_for_signature_tests';
  const baseUrl = 'http://127.0.0.1:3000';

  beforeAll(async () => {
    process.env.TWILIO_AUTH_TOKEN = authToken;
    process.env.TWILIO_WEBHOOK_BASE_URL = baseUrl;
    const ctx = await createE2eApplication();
    app = ctx.app;
  });

  afterAll(async () => {
    delete process.env.TWILIO_AUTH_TOKEN;
    delete process.env.TWILIO_WEBHOOK_BASE_URL;
    await app.close();
  });

  it('rejects missing signature', async () => {
    await request(app.getHttpServer())
      .post('/v1/webhooks/twilio/status')
      .type('form')
      .send({ MessageSid: 'SM123', MessageStatus: 'delivered' })
      .expect(401);
  });

  it('accepts valid signature', async () => {
    const params = { MessageSid: 'SM456', MessageStatus: 'delivered', To: '+15550001111', From: '+15550002222' };
    const url = `${baseUrl}/v1/webhooks/twilio/status`;
    const signature = twilio.getExpectedTwilioSignature(authToken, url, params);

    await request(app.getHttpServer())
      .post('/v1/webhooks/twilio/status')
      .set('X-Twilio-Signature', signature)
      .type('form')
      .send(params)
      .expect(200);
  });
});
