import {
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { AuditService } from '../../audit/services/audit.service';
import { PrismaService } from '../../prisma/prisma.service';
import { CleanupEventsListService } from './cleanup-events-list.service';

@Injectable()
export class CleanupEventsParticipantsAdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly list: CleanupEventsListService,
  ) {}

  async removeParticipant(eventId: string, userId: string, actor: AuthenticatedUser) {
    const event = await this.prisma.cleanupEvent.findUnique({
      where: { id: eventId },
      select: { id: true, participantCount: true },
    });
    if (!event) {
      throw new NotFoundException({
        code: 'CLEANUP_EVENT_NOT_FOUND',
        message: 'Cleanup event not found',
      });
    }

    const participant = await this.prisma.eventParticipant.findUnique({
      where: { eventId_userId: { eventId, userId } },
      select: { id: true },
    });
    if (!participant) {
      throw new NotFoundException({
        code: 'EVENT_PARTICIPANT_NOT_FOUND',
        message: 'Participant not found for this event',
      });
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.eventParticipant.delete({
        where: { eventId_userId: { eventId, userId } },
      });
      const nextCount = Math.max(0, event.participantCount - 1);
      if (nextCount !== event.participantCount) {
        await tx.cleanupEvent.update({
          where: { id: eventId },
          data: { participantCount: nextCount },
        });
      }
    });

    await this.audit.log({
      actorId: actor.userId,
      action: 'CLEANUP_EVENT_PARTICIPANT_REMOVED',
      resourceType: 'CleanupEvent',
      resourceId: eventId,
      metadata: { userId },
    });

    return this.list.findOne(eventId);
  }
}
