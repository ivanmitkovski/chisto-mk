/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { NotificationType } from '../../src/prisma-client';
import { EmailUnsubscribeTokenService } from '../../src/email/email-unsubscribe-token.service';
import { PrismaService } from '../../src/prisma/prisma.service';
import { createE2eApplication } from './helpers/bootstrap-app';
import { registerCitizen } from './helpers/auth-helper';

describe('Email unsubscribe (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let tokens: EmailUnsubscribeTokenService;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
    prisma = ctx.prisma;
    tokens = app.get(EmailUnsubscribeTokenService);
  });

  afterAll(async () => {
    await app.close();
  });

  it('POST one-click unsubscribe mutes email for notification type', async () => {
    const citizen = await registerCitizen(app, 'email_unsub');
    const user = await prisma.user.findUniqueOrThrow({
      where: { email: citizen.email },
      select: { id: true },
    });
    const token = tokens.sign(user.id, NotificationType.COMMENT);

    await request(app.getHttpServer())
      .post('/v1/notifications/email/unsubscribe')
      .send({ token })
      .expect(204);

    const pref = await prisma.userNotificationPreference.findUnique({
      where: {
        userId_type: { userId: user.id, type: NotificationType.COMMENT },
      },
    });
    expect(pref?.emailMuted).toBe(true);
  });
});
