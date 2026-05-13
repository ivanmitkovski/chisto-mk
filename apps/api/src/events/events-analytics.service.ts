import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '../prisma-client';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { buildEventAnalyticsPayload, type CheckInsByHourPoint } from './event-analytics.aggregation';
import { isEventsStaff } from './events-auth.util';
import { EventsRepository } from './events.repository';

/**
 * Single-event attendance analytics (organizer or staff).
 */
@Injectable()
export class EventsAnalyticsService {
  constructor(private readonly eventsRepository: EventsRepository) {}

  async getAnalytics(id: string, user: AuthenticatedUser) {
    const event = await this.eventsRepository.prisma.cleanupEvent.findUnique({
      where: { id },
      select: { organizerId: true, participantCount: true },
    });
    if (event == null) {
      throw new NotFoundException({ code: 'EVENT_NOT_FOUND', message: 'Event not found' });
    }
    if (event.organizerId !== user.userId && !isEventsStaff(user)) {
      throw new ForbiddenException({
        code: 'NOT_EVENT_ORGANIZER',
        message: 'Only the organizer can view analytics',
      });
    }

    const ANALYTICS_JOINER_SAMPLE_CAP = 5_000;
    const [participants, checkedInCount, hourRows] = await Promise.all([
      this.eventsRepository.prisma.eventParticipant.findMany({
        where: { eventId: id },
        select: { joinedAt: true },
        orderBy: { joinedAt: 'asc' },
        take: ANALYTICS_JOINER_SAMPLE_CAP,
      }),
      this.eventsRepository.prisma.eventCheckIn.count({ where: { eventId: id } }),
      // RAW SQL: UTC hour histogram over check-ins; Prisma groupBy cannot target EXTRACT(HOUR FROM timestamptz AT TIME ZONE 'UTC').
      this.eventsRepository.prisma.$queryRaw<Array<{ hour: number; count: bigint }>>(
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
}
