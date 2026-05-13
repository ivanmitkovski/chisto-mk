import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ReportsUploadService } from '../reports/reports-upload.service';

@Injectable()
export class EventChatPresenceRosterService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly uploads: ReportsUploadService,
  ) {}

  async listParticipants(eventId: string): Promise<{
    data: {
      count: number;
      participants: { id: string; displayName: string; avatarUrl: string | null }[];
    };
    meta: { timestamp: string };
  }> {
    const event = await this.prisma.cleanupEvent.findFirst({
      where: { id: eventId },
      select: { organizerId: true },
    });
    if (!event) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }

    const rows = await this.prisma.eventParticipant.findMany({
      where: { eventId },
      orderBy: { joinedAt: 'asc' },
      take: 200,
      select: {
        user: {
          select: { id: true, firstName: true, lastName: true, avatarObjectKey: true },
        },
      },
    });

    const participants: { id: string; displayName: string; avatarUrl: string | null }[] = [];
    const seen = new Set<string>();

    let org: {
      id: string;
      firstName: string;
      lastName: string;
      avatarObjectKey: string | null;
    } | null = null;
    if (event.organizerId) {
      org = await this.prisma.user.findUnique({
        where: { id: event.organizerId },
        select: {
          id: true,
          firstName: true,
          lastName: true,
          avatarObjectKey: true,
        },
      });
    }

    const keysToSign = new Set<string>();
    if (org?.avatarObjectKey) {
      keysToSign.add(org.avatarObjectKey);
    }
    for (const r of rows) {
      if (r.user.avatarObjectKey) {
        keysToSign.add(r.user.avatarObjectKey);
      }
    }
    const signedByKey = new Map<string, string | null>();
    await Promise.all(
      [...keysToSign].map(async (key) => {
        signedByKey.set(key, await this.uploads.signPrivateObjectKey(key));
      }),
    );

    if (org) {
      participants.push({
        id: org.id,
        displayName: `${org.firstName} ${org.lastName}`.trim(),
        avatarUrl: org.avatarObjectKey ? (signedByKey.get(org.avatarObjectKey) ?? null) : null,
      });
      seen.add(org.id);
    }

    for (const r of rows) {
      if (seen.has(r.user.id)) {
        continue;
      }
      if (participants.length >= 50) {
        break;
      }
      participants.push({
        id: r.user.id,
        displayName: `${r.user.firstName} ${r.user.lastName}`.trim(),
        avatarUrl: r.user.avatarObjectKey ? (signedByKey.get(r.user.avatarObjectKey) ?? null) : null,
      });
      seen.add(r.user.id);
    }

    const nParticipants = await this.prisma.eventParticipant.count({ where: { eventId } });
    const organizerJoined =
      event.organizerId != null
        ? await this.prisma.eventParticipant.findUnique({
            where: { eventId_userId: { eventId, userId: event.organizerId } },
            select: { id: true },
          })
        : null;
    const count = nParticipants + (event.organizerId != null && organizerJoined == null ? 1 : 0);

    return {
      data: { count, participants },
      meta: { timestamp: new Date().toISOString() },
    };
  }
}
