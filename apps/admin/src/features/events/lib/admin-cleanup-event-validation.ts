/**
 * Client-side validation aligned with API cleanup-event DTOs
 * (`apps/api/src/cleanup-events/dto/create-cleanup-event.dto.ts`,
 * `patch-cleanup-event.dto.ts`). Keep `RRULE_PRINTABLE_ASCII` in sync with server `@Matches`.
 */
/** Printable ASCII (tab, LF, CR, space through tilde) — keep in sync with API `@Matches`. */
export const RRULE_PRINTABLE_ASCII = /^[\t\n\r\u0020-\u007e]*$/;

const TITLE_MAX = 200;
const DESCRIPTION_MAX = 10_000;
const RRULE_MAX = 2048;

export type CleanupEventFieldKey =
  | 'title'
  | 'description'
  | 'recurrenceRule'
  | 'scheduledAt'
  | 'endAt'
  | 'completedAt'
  | 'participantCount'
  | 'declineReason';

export type CleanupEventFieldErrors = Partial<Record<CleanupEventFieldKey, string>>;

export function parseValidDate(value: string): Date | null {
  const trimmed = value.trim();
  if (!trimmed) {
    return null;
  }
  const d = new Date(trimmed);
  return Number.isNaN(d.getTime()) ? null : d;
}

export function validateParticipantCount(n: number): string | null {
  if (!Number.isInteger(n) || n < 0) {
    return 'Participant count must be a whole number of zero or more.';
  }
  return null;
}

export function validateTitle(title: string): string | null {
  const t = title.trim();
  if (t.length > TITLE_MAX) {
    return `Title must be at most ${TITLE_MAX} characters.`;
  }
  return null;
}

export function validateDescription(description: string): string | null {
  if (description.length > DESCRIPTION_MAX) {
    return `Description must be at most ${DESCRIPTION_MAX} characters.`;
  }
  return null;
}

export function validateRecurrenceRule(recurrenceRule: string): string | null {
  const r = recurrenceRule.trim();
  if (!r) {
    return null;
  }
  if (r.length > RRULE_MAX) {
    return `Recurrence rule must be at most ${RRULE_MAX} characters.`;
  }
  if (!RRULE_PRINTABLE_ASCII.test(r)) {
    return 'Recurrence rule must use printable ASCII only (tabs, newlines, and basic Latin).';
  }
  return null;
}

/** `datetime-local` value or other string parseable by `Date`. */
export function validateScheduledAtInput(raw: string): string | null {
  if (!raw.trim()) {
    return 'Scheduled date and time are required.';
  }
  const d = parseValidDate(raw);
  if (!d) {
    return 'Scheduled date and time are not valid.';
  }
  return null;
}

/** Start/end are browser-local `datetime-local` values or ISO strings parseable by `Date`. */
export function validateScheduleStartEndWindow(input: {
  scheduledAtRaw: string;
  endAtRaw: string;
}): Pick<CleanupEventFieldErrors, 'scheduledAt' | 'endAt'> {
  const out: Pick<CleanupEventFieldErrors, 'scheduledAt' | 'endAt'> = {};
  const schedErr = validateScheduledAtInput(input.scheduledAtRaw);
  if (schedErr) {
    out.scheduledAt = schedErr;
    return out;
  }
  if (!input.endAtRaw.trim()) {
    out.endAt = 'End date and time are required.';
    return out;
  }
  const start = parseValidDate(input.scheduledAtRaw);
  const end = parseValidDate(input.endAtRaw);
  if (!end) {
    out.endAt = 'End date and time are not valid.';
    return out;
  }
  if (start != null && end.getTime() <= start.getTime()) {
    out.endAt = 'End must be after start.';
    return out;
  }
  if (start != null) {
    const startDay = new Date(start.getFullYear(), start.getMonth(), start.getDate());
    const endDay = new Date(end.getFullYear(), end.getMonth(), end.getDate());
    if (endDay.getTime() !== startDay.getTime()) {
      out.endAt = 'Event must end on the same calendar day as the start.';
    } else {
      const endOfStartDay = new Date(startDay);
      endOfStartDay.setHours(23, 59, 59, 999);
      if (end.getTime() > endOfStartDay.getTime()) {
        out.endAt = 'Event must not end after 23:59 on the start day.';
      }
    }
  }
  return out;
}

/** ISO string from API or local datetime string. */
export function validateScheduledAtIsoOrLocal(raw: string): string | null {
  if (!raw.trim()) {
    return 'Scheduled date and time are required.';
  }
  const d = parseValidDate(raw);
  if (!d) {
    return 'Scheduled date and time are not valid.';
  }
  return null;
}

export function validateCompletedAtInput(raw: string): string | null {
  if (!raw.trim()) {
    return null;
  }
  const d = parseValidDate(raw);
  if (!d) {
    return 'Completed date and time are not valid.';
  }
  return null;
}

export function validateDeclineReason(reason: string): string | null {
  const t = reason.trim();
  if (t.length < 1) {
    return 'A decline reason is required (1–2000 characters).';
  }
  if (t.length > 2000) {
    return 'Decline reason must be at most 2000 characters.';
  }
  return null;
}

export function validateCleanupEventForm(input: {
  title: string;
  description: string;
  recurrenceRule: string;
  scheduledAtRaw: string;
  endAtRaw: string;
  participantCount: number;
}): CleanupEventFieldErrors {
  const errors: CleanupEventFieldErrors = {};
  const titleErr = validateTitle(input.title);
  if (titleErr) {
    errors.title = titleErr;
  }
  const descErr = validateDescription(input.description);
  if (descErr) {
    errors.description = descErr;
  }
  const rrErr = validateRecurrenceRule(input.recurrenceRule);
  if (rrErr) {
    errors.recurrenceRule = rrErr;
  }
  const windowErrs = validateScheduleStartEndWindow({
    scheduledAtRaw: input.scheduledAtRaw,
    endAtRaw: input.endAtRaw,
  });
  Object.assign(errors, windowErrs);
  const pcErr = validateParticipantCount(input.participantCount);
  if (pcErr) {
    errors.participantCount = pcErr;
  }
  return errors;
}

export function validateCleanupEventDetailForm(input: {
  title: string;
  description: string;
  recurrenceRule: string;
  scheduledAtValue: string;
  /** When provided (upcoming edit), enforces multi-day span with [scheduledAtValue]. */
  endAtValue?: string;
  participantCount: number;
  completedAtLocal?: string;
}): CleanupEventFieldErrors {
  const errors: CleanupEventFieldErrors = {};
  const titleErr = validateTitle(input.title);
  if (titleErr) {
    errors.title = titleErr;
  }
  const descErr = validateDescription(input.description);
  if (descErr) {
    errors.description = descErr;
  }
  const rrErr = validateRecurrenceRule(input.recurrenceRule);
  if (rrErr) {
    errors.recurrenceRule = rrErr;
  }
  if (input.endAtValue !== undefined) {
    const windowErrs = validateScheduleStartEndWindow({
      scheduledAtRaw: input.scheduledAtValue,
      endAtRaw: input.endAtValue,
    });
    Object.assign(errors, windowErrs);
  } else {
    const schedErr = validateScheduledAtIsoOrLocal(input.scheduledAtValue);
    if (schedErr) {
      errors.scheduledAt = schedErr;
    }
  }
  const pcErr = validateParticipantCount(input.participantCount);
  if (pcErr) {
    errors.participantCount = pcErr;
  }
  if (input.completedAtLocal !== undefined && input.completedAtLocal.trim()) {
    const cErr = validateCompletedAtInput(input.completedAtLocal);
    if (cErr) {
      errors.completedAt = cErr;
    }
  }
  return errors;
}
