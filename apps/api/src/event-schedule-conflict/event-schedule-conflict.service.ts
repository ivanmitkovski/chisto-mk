import { Injectable } from '@nestjs/common';
import {
  CleanupEventStatus,
  EcoEventLifecycleStatus,
} from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { DUPLICATE_EVENT_BUFFER_HOURS } from './event-schedule-conflict.constants';
import type { ConflictingEventSummary } from './event-schedule-conflict.types';

export type ScheduleConflictCheckParams = {
  siteId: string;
  scheduledAt: Date;
  endAt: Date | null;
  excludeEventId?: string;
};

function addHours(d: Date, hours: number): Date {
  return new Date(d.getTime() + hours * 60 * 60 * 1000);
}

/** Buffered interval [start, end] for overlap test. */
function bufferedInterval(
  scheduledAt: Date,
  endAt: Date | null,
  bufferHours: number,
): { start: Date; end: Date } {
  const end = endAt ?? scheduledAt;
  return {
    start: addHours(scheduledAt, -bufferHours),
    end: addHours(end, bufferHours),
  };
}

function intervalsOverlap(
  a: { start: Date; end: Date },
  b: { start: Date; end: Date },
): boolean {
  return a.start.getTime() < b.end.getTime() && b.start.getTime() < a.end.getTime();
}

@Injectable()
export class EventScheduleConflictService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Returns the first conflicting active event at the same site, or null.
   * Active = not DECLINED moderation, lifecycle not COMPLETED/CANCELLED.
   */
  async findConflictingEvent(
    params: ScheduleConflictCheckParams,
  ): Promise<ConflictingEventSummary | null> {
    const { siteId, scheduledAt, endAt, excludeEventId } = params;
    const buffer = DUPLICATE_EVENT_BUFFER_HOURS;
    const newIv = bufferedInterval(scheduledAt, endAt, buffer);

    // Narrow fetch: events that could possibly overlap (scheduled start within extended window).
    const windowStart = addHours(newIv.start, -24 * 7);
    const windowEnd = addHours(newIv.end, 24 * 7);

    const rows = await this.prisma.cleanupEvent.findMany({
      where: {
        siteId,
        status: { not: CleanupEventStatus.DECLINED },
        lifecycleStatus: {
          notIn: [
            EcoEventLifecycleStatus.COMPLETED,
            EcoEventLifecycleStatus.CANCELLED,
          ],
        },
        scheduledAt: {
          gte: windowStart,
          lte: windowEnd,
        },
        ...(excludeEventId != null && excludeEventId.length > 0
          ? { NOT: { id: excludeEventId } }
          : {}),
      },
      select: {
        id: true,
        title: true,
        scheduledAt: true,
        endAt: true,
      },
      take: 200,
    });

    const newBuffered = newIv;
    for (const row of rows) {
      const existingBuffered = bufferedInterval(
        row.scheduledAt,
        row.endAt,
        buffer,
      );
      if (intervalsOverlap(newBuffered, existingBuffered)) {
        return {
          id: row.id,
          title: row.title,
          scheduledAt: row.scheduledAt,
        };
      }
    }

    // Second pass: long events whose scheduledAt is before windowStart but endAt overlaps.
    const longTail = await this.prisma.cleanupEvent.findMany({
      where: {
        siteId,
        status: { not: CleanupEventStatus.DECLINED },
        lifecycleStatus: {
          notIn: [
            EcoEventLifecycleStatus.COMPLETED,
            EcoEventLifecycleStatus.CANCELLED,
          ],
        },
        scheduledAt: { lt: windowStart },
        endAt: { not: null, gte: windowStart },
        ...(excludeEventId != null && excludeEventId.length > 0
          ? { NOT: { id: excludeEventId } }
          : {}),
      },
      select: {
        id: true,
        title: true,
        scheduledAt: true,
        endAt: true,
      },
      take: 50,
    });

    for (const row of longTail) {
      const existingBuffered = bufferedInterval(
        row.scheduledAt,
        row.endAt,
        buffer,
      );
      if (intervalsOverlap(newBuffered, existingBuffered)) {
        return {
          id: row.id,
          title: row.title,
          scheduledAt: row.scheduledAt,
        };
      }
    }

    return null;
  }
}
