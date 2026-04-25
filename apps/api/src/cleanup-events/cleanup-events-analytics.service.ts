import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import {
  buildEventAnalyticsPayload,
  type CheckInsByHourPoint,
  type EventAnalyticsPayload,
} from '../events/event-analytics.aggregation';

const AUDIT_TRAIL_LIMIT = 50;
/** Cap joiner series rows to keep analytics bounded for very large events (headline uses participantCount). */
const ANALYTICS_JOINER_SAMPLE_CAP = 5_000;
const LIST_PARTICIPANTS_CAP = 5_000;

@Injectable()
export class CleanupEventsAnalyticsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  async getAnalytics(id: string): Promise<EventAnalyticsPayload> {
    const event = await this.prisma.cleanupEvent.findUnique({
      where: { id },
      select: { participantCount: true },
    });
    if (event == null) {
      throw new NotFoundException({ code: 'CLEANUP_EVENT_NOT_FOUND', message: 'Cleanup event not found' });
    }

    const [participants, checkedInCount, hourRows] = await Promise.all([
      this.prisma.eventParticipant.findMany({
        where: { eventId: id },
        select: { joinedAt: true },
        orderBy: { joinedAt: 'asc' },
        take: ANALYTICS_JOINER_SAMPLE_CAP,
      }),
      this.prisma.eventCheckIn.count({ where: { eventId: id } }),
      this.prisma.$queryRaw<Array<{ hour: number; count: bigint }>>(
        Prisma.sql`
          SELECT (EXTRACT(HOUR FROM "checkedInAt" AT TIME ZONE 'UTC'))::int AS hour,
                 COUNT(*)::bigint AS count
          FROM "EventCheckIn"
          WHERE "eventId" = ${id}
          GROUP BY 1
        `,
      ),
    ]);

    const hourCounts = Array.from({ length: 24 }, () => 0);
    for (const row of hourRows) {
      if (row.hour >= 0 && row.hour < 24) {
        hourCounts[row.hour] = Number(row.count);
      }
    }
    const checkInsByHour: CheckInsByHourPoint[] = hourCounts.map((count, hour) => ({ hour, count }));

    return buildEventAnalyticsPayload({
      participantCount: event.participantCount,
      participantsJoinedAt: participants.map((p) => p.joinedAt),
      checkInsCheckedAt: [],
      checkedInCountOverride: checkedInCount,
      checkInsByHourOverride: checkInsByHour,
    });
  }

  async listParticipants(id: string) {
    const existing = await this.prisma.cleanupEvent.findUnique({ where: { id }, select: { id: true } });
    if (!existing) {
      throw new NotFoundException({
        code: 'CLEANUP_EVENT_NOT_FOUND',
        message: 'Cleanup event not found',
      });
    }
    const rows = await this.prisma.eventParticipant.findMany({
      where: { eventId: id },
      orderBy: { joinedAt: 'asc' },
      take: LIST_PARTICIPANTS_CAP,
      select: {
        userId: true,
        joinedAt: true,
        user: { select: { firstName: true, lastName: true, email: true } },
      },
    });
    return {
      data: rows.map((r) => ({
        userId: r.userId,
        joinedAt: r.joinedAt.toISOString(),
        displayName: `${r.user.firstName} ${r.user.lastName}`.trim(),
        email: r.user.email,
      })),
    };
  }

  async listAuditTrail(id: string, query: { page?: number; limit?: number }) {
    const existing = await this.prisma.cleanupEvent.findUnique({ where: { id }, select: { id: true } });
    if (!existing) {
      throw new NotFoundException({
        code: 'CLEANUP_EVENT_NOT_FOUND',
        message: 'Cleanup event not found',
      });
    }
    const page = query.page ?? 1;
    const limit = Math.min(query.limit ?? AUDIT_TRAIL_LIMIT, 100);
    return this.audit.listForAdmin({
      page,
      limit,
      resourceType: 'CleanupEvent',
      resourceId: id,
    });
  }
}
