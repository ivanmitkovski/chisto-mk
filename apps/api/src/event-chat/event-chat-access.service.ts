import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CleanupEventStatus, Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';

function chatEventVisibilityWhere(userId: string): Prisma.CleanupEventWhereInput {
  return {
    OR: [{ status: CleanupEventStatus.APPROVED }, { organizerId: userId }],
  };
}

/**
 * Shared organizer/participant check for REST ([`EventChatAccessGuard`]) and WebSocket room join/typing.
 *
 * **Authorization invariants**
 * - Every chat mutation path used by clients must enforce access through this service (or equivalent
 *   `assertCanAccessEventChat`) after authentication — never trust `eventId` from the body alone for authorization.
 * - REST routes rely on [`EventChatAccessGuard`] (runs after JWT); the chat gateway calls the same primitive on
 *   `join` and `typing` after deriving `userId` from the verified JWT — never from client-supplied user id fields.
 * - `eventId` in URL params is the sole event scope for REST; WebSocket payloads must still supply `eventId` for
 *   room targeting, but access is always re-checked server-side.
 */
@Injectable()
export class EventChatAccessService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * @throws NotFoundException when the event is missing or not visible
   * @throws ForbiddenException when the user is not organizer nor joined participant
   */
  async assertCanAccessEventChat(userId: string, eventId: string): Promise<void> {
    const trimmed = eventId.trim();
    if (!trimmed) {
      throw new ForbiddenException({
        code: 'EVENT_CHAT_FORBIDDEN',
        message: 'Chat access denied',
      });
    }

    const event = await this.prisma.cleanupEvent.findFirst({
      where: { id: trimmed, ...chatEventVisibilityWhere(userId) },
      select: {
        id: true,
        organizerId: true,
      },
    });
    if (!event) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }

    if (event.organizerId === userId) {
      return;
    }

    const joined = await this.prisma.eventParticipant.findUnique({
      where: {
        eventId_userId: { eventId: trimmed, userId },
      },
      select: { id: true },
    });
    if (!joined) {
      throw new ForbiddenException({
        code: 'EVENT_CHAT_NOT_PARTICIPANT',
        message: 'Join this event to use the chat',
      });
    }
  }
}
