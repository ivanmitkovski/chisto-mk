import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import type { MuteChatDto } from './dto/mute-chat.dto';

@Injectable()
export class EventChatPresenceMuteService {
  constructor(private readonly prisma: PrismaService) {}

  async getMuteStatus(
    eventId: string,
    user: AuthenticatedUser,
  ): Promise<{ data: { muted: boolean }; meta: { timestamp: string } }> {
    const row = await this.prisma.eventChatMute.findUnique({
      where: {
        eventId_userId: { eventId, userId: user.userId },
      },
      select: { id: true },
    });
    return {
      data: { muted: row != null },
      meta: { timestamp: new Date().toISOString() },
    };
  }

  async setMuteStatus(
    eventId: string,
    user: AuthenticatedUser,
    dto: MuteChatDto,
  ): Promise<{ data: { ok: true; muted: boolean }; meta: { timestamp: string } }> {
    if (dto.muted) {
      await this.prisma.eventChatMute.upsert({
        where: {
          eventId_userId: { eventId, userId: user.userId },
        },
        create: { eventId, userId: user.userId },
        update: {},
      });
    } else {
      await this.prisma.eventChatMute.deleteMany({
        where: { eventId, userId: user.userId },
      });
    }
    return {
      data: { ok: true, muted: dto.muted },
      meta: { timestamp: new Date().toISOString() },
    };
  }
}
