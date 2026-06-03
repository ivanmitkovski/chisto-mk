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
    const agent = request(app.getHttpServer());

    const list = await agent
      .get('/v1/notifications/preferences')
      .set('Authorization', `Bearer ${citizen.accessToken}`)
      .expect(200);
    expect(Array.isArray(list.body.data)).toBe(true);

    const patch = await agent
      .patch(`/v1/notifications/preferences/${NotificationType.COMMENT}`)
      .set('Authorization', `Bearer ${citizen.accessToken}`)
      .send({ muted: true, emailMuted: true })
      .expect(200);
    expect(patch.body.type).toBe(NotificationType.COMMENT);
    expect(patch.body.muted).toBe(true);
  });
});
