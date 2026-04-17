import { ConflictException } from '@nestjs/common';
import type { ConflictingEventSummary } from './event-schedule-conflict.types';

export function duplicateEventConflict(c: ConflictingEventSummary): ConflictException {
  return new ConflictException({
    code: 'DUPLICATE_EVENT',
    message: 'An active event already exists for this site at the requested time.',
    details: {
      conflictingEvent: {
        id: c.id,
        title: c.title,
        scheduledAt: c.scheduledAt.toISOString(),
      },
    },
  });
}
