/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { apiPath } from './helpers/api-path';
import { registerCitizen } from './helpers/auth-helper';
import {
  createApprovedEventWithParticipant,
  deleteApprovedEventFixture,
} from './helpers/approved-event-with-participant';
import { PrismaService } from '../../src/prisma/prisma.service';
import { AccountErasureCronService } from '../../src/auth/services/account-erasure-cron.service';
import { UserStatus } from '../../src/prisma-client';

describe('Account erasure (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
    prisma = ctx.prisma;
  });

  afterAll(async () => {
    await app.close();
  });

  it('removes device tokens and notification outbox rows on delete', async () => {
    const u = await registerCitizen(app, 'erasure_fcm');
    await prisma.userDeviceToken.create({
      data: {
        userId: (await prisma.user.findFirst({ where: { email: u.email }, select: { id: true } }))!.id,
        token: `e2e-fcm-${Date.now()}`,
        platform: 'IOS',
      },
    });
    const user = await prisma.user.findFirst({ where: { email: u.email } });
    expect(user).toBeTruthy();

    await request(app.getHttpServer())
      .delete(apiPath('/auth/me'))
      .set('Authorization', `Bearer ${u.accessToken}`)
      .expect(204);

    const tokens = await prisma.userDeviceToken.count({ where: { userId: user!.id } });
    expect(tokens).toBe(0);
  });

  it('anonymizes profile fields on self-delete (no English placeholder name)', async () => {
    const u = await registerCitizen(app, 'erasure_anonymize');
    const userBefore = await prisma.user.findFirst({ where: { email: u.email } });
    expect(userBefore).toBeTruthy();

    await request(app.getHttpServer())
      .delete(apiPath('/auth/me'))
      .set('Authorization', `Bearer ${u.accessToken}`)
      .expect(204);

    const userAfter = await prisma.user.findUnique({ where: { id: userBefore!.id } });
    expect(userAfter?.status).toBe(UserStatus.DELETED);
    expect(userAfter?.firstName).toBe('');
    expect(userAfter?.lastName).toBe('');
    expect(userAfter?.deletedAt).toBeTruthy();
  });

  it('hard purge preserves civic participation rows with null userId', async () => {
    const organizer = await registerCitizen(app, 'erasure_org');
    const participant = await registerCitizen(app, 'erasure_participant');
    const organizerUser = await prisma.user.findFirstOrThrow({
      where: { email: organizer.email },
      select: { id: true },
    });
    const participantUser = await prisma.user.findFirstOrThrow({
      where: { email: participant.email },
      select: { id: true },
    });

    const fixture = await createApprovedEventWithParticipant(
      prisma,
      organizerUser.id,
      participantUser.id,
    );

    await request(app.getHttpServer())
      .delete(apiPath('/auth/me'))
      .set('Authorization', `Bearer ${participant.accessToken}`)
      .expect(204);

    const cutoff = new Date(Date.now() - 31 * 24 * 60 * 60 * 1000);
    await prisma.user.update({
      where: { id: participantUser.id },
      data: { deletedAt: cutoff },
    });

    const cron = app.get(AccountErasureCronService);
    const purged = await cron.purgeExpired();
    expect(purged).toBeGreaterThan(0);

    const participation = await prisma.eventParticipant.findFirst({
      where: { eventId: fixture.eventId, userId: null },
    });
    expect(participation).toBeTruthy();

    const event = await prisma.cleanupEvent.findUniqueOrThrow({
      where: { id: fixture.eventId },
      select: { participantCount: true },
    });
    expect(event.participantCount).toBe(1);

    await deleteApprovedEventFixture(prisma, fixture);
    await prisma.user.deleteMany({
      where: { id: { in: [organizerUser.id] } },
    });
  });
});
