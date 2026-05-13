import type { PrismaService } from '../../../src/prisma/prisma.service';
import {
  CleanupEventStatus,
  EcoEventCategory,
  EcoEventLifecycleStatus,
} from '../../../src/prisma-client';

export type ApprovedEventFixture = {
  siteId: string;
  eventId: string;
};

/**
 * Minimal Site + APPROVED CleanupEvent + EventParticipant for WebSocket journey tests
 * (event chat join/typing, check-in join).
 */
export async function createApprovedEventWithParticipant(
  prisma: PrismaService,
  organizerUserId: string,
  participantUserId: string,
): Promise<ApprovedEventFixture> {
  const site = await prisma.site.create({
    data: {
      latitude: 41.9973,
      longitude: 21.4254,
      description: 'e2e_ws_fixture_site',
    },
  });
  const scheduledAt = new Date(Date.now() + 86_400_000);
  const event = await prisma.cleanupEvent.create({
    data: {
      siteId: site.id,
      title: 'E2e WS fixture event',
      description: 'fixture',
      category: EcoEventCategory.GENERAL_CLEANUP,
      scheduledAt,
      status: CleanupEventStatus.APPROVED,
      lifecycleStatus: EcoEventLifecycleStatus.UPCOMING,
      organizerId: organizerUserId,
      participantCount: 1,
    },
  });
  await prisma.eventParticipant.create({
    data: {
      eventId: event.id,
      userId: participantUserId,
    },
  });
  return { siteId: site.id, eventId: event.id };
}

export async function deleteApprovedEventFixture(
  prisma: PrismaService,
  fixture: ApprovedEventFixture,
): Promise<void> {
  await prisma.cleanupEvent.deleteMany({ where: { id: fixture.eventId } });
  await prisma.site.deleteMany({ where: { id: fixture.siteId } });
}
