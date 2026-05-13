import { BadRequestException, Injectable } from '@nestjs/common';
import { EventScheduleConflictService } from '../event-schedule-conflict/event-schedule-conflict.service';
import {
  assertEndSameSkopjeCalendarDayUtc,
  defaultEndSameSkopjeCalendarDayUtc,
} from '../common/validation/event-calendar-span.validation';
import type { CheckEventConflictQueryDto } from './dto/check-event-conflict-query.dto';

@Injectable()
export class EventsScheduleConflictPreviewQueryService {
  constructor(private readonly scheduleConflict: EventScheduleConflictService) {}

  /**
   * Read-only preview for create/edit forms; does not return 409.
   */
  async checkScheduleConflictPreview(query: CheckEventConflictQueryDto): Promise<{
    hasConflict: boolean;
    conflictingEvent?: { id: string; title: string; scheduledAt: string };
  }> {
    const scheduledAt = new Date(query.scheduledAt);
    if (Number.isNaN(scheduledAt.getTime())) {
      throw new BadRequestException({
        code: 'INVALID_SCHEDULED_AT',
        message: 'Invalid scheduledAt',
      });
    }
    let endAt: Date | null = null;
    if (query.endAt != null && query.endAt.trim() !== '') {
      endAt = new Date(query.endAt);
      if (Number.isNaN(endAt.getTime()) || endAt.getTime() <= scheduledAt.getTime()) {
        throw new BadRequestException({
          code: 'INVALID_END_AT',
          message: 'endAt must be after scheduledAt',
        });
      }
      assertEndSameSkopjeCalendarDayUtc({ scheduledAt, endAt });
    } else {
      endAt = defaultEndSameSkopjeCalendarDayUtc(scheduledAt);
    }
    const row = await this.scheduleConflict.findConflictingEvent({
      siteId: query.siteId,
      scheduledAt,
      endAt,
      ...(query.excludeEventId != null && query.excludeEventId !== ''
        ? { excludeEventId: query.excludeEventId }
        : {}),
    });
    if (row == null) {
      return { hasConflict: false };
    }
    return {
      hasConflict: true,
      conflictingEvent: {
        id: row.id,
        title: row.title,
        scheduledAt: row.scheduledAt.toISOString(),
      },
    };
  }
}
