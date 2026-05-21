/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { NotificationType } from '../../src/prisma-client';
import { createE2eApplication } from './helpers/bootstrap-app';
import { registerCitizen } from './helpers/auth-helper';

describe('Notification preferences (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
  });

  afterAll(async () => {
    await app.close();
  });

  it('lists and updates preferences for authenticated user', async () => {
    const citizen = await registerCitizen(app, 'notif_prefs');
    const agent = request(app.getHttpServer()).set('Authorization', `Bearer ${citizen.accessToken}`);

    const list = await agent.get('/notifications/preferences').expect(200);
    expect(Array.isArray(list.body)).toBe(true);

    const patch = await agent
      .patch(`/notifications/preferences/${NotificationType.SITE_COMMENT}`)
      .send({ pushEnabled: false, emailEnabled: false })
      .expect(200);
    expect(patch.body.type).toBe(NotificationType.SITE_COMMENT);
    expect(patch.body.pushEnabled).toBe(false);
  });
});
