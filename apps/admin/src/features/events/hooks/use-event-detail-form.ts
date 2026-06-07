'use client';

import { useEffect, useMemo, useState } from 'react';
import type { CleanupEventDetail } from '@/features/events/data/events-adapter';
import {
  type CleanupEventFieldErrors,
  type CleanupEventFieldKey,
} from '@/features/events/lib/admin-cleanup-event-validation';
import {
  defaultEndAtIsoFromScheduled,
  toDatetimeLocalField,
} from '@/features/events/lib/event-admin-datetime';
import type { CleanupEventFormValues } from '@/features/events/components/cleanup-event-form-fields';
import { useScheduleConflictPreview } from '@/features/events/lib/use-schedule-conflict-preview';

export function useEventDetailForm(event: CleanupEventDetail) {
  const [title, setTitle] = useState(event.title);
  const [description, setDescription] = useState(event.description);
  const [recurrenceRule, setRecurrenceRule] = useState(event.recurrenceRule ?? '');
  const [scheduledAt, setScheduledAt] = useState(event.scheduledAt);
  const [endAt, setEndAt] = useState(() =>
    event.endAt ? new Date(event.endAt).toISOString() : defaultEndAtIsoFromScheduled(event.scheduledAt),
  );
  const [completedAt, setCompletedAt] = useState(event.completedAt ?? '');
  const [participantCount, setParticipantCount] = useState(event.participantCount);
  const [fieldErrors, setFieldErrors] = useState<CleanupEventFieldErrors>({});
  const [scheduleConflictOverride, setScheduleConflictOverride] = useState(false);

  useEffect(() => {
    setScheduleConflictOverride(false);
  }, [scheduledAt, endAt, event.site.id]);

  useEffect(() => {
    setTitle(event.title);
    setDescription(event.description);
    setRecurrenceRule(event.recurrenceRule ?? '');
    setScheduledAt(event.scheduledAt);
    if (event.endAt) {
      setEndAt(new Date(event.endAt).toISOString());
    } else {
      setEndAt(defaultEndAtIsoFromScheduled(event.scheduledAt));
    }
    setCompletedAt(event.completedAt ?? '');
    setParticipantCount(event.participantCount);
  }, [
    event.id,
    event.title,
    event.description,
    event.recurrenceRule,
    event.scheduledAt,
    event.endAt,
    event.completedAt,
    event.participantCount,
  ]);

  const scheduledAtIso = useMemo(() => {
    if (!scheduledAt.trim()) {
      return null;
    }
    const parsed = new Date(scheduledAt);
    return Number.isNaN(parsed.getTime()) ? null : parsed.toISOString();
  }, [scheduledAt]);

  const endAtIso = useMemo(() => {
    if (!endAt.trim()) {
      return null;
    }
    const parsed = new Date(endAt);
    return Number.isNaN(parsed.getTime()) ? null : parsed.toISOString();
  }, [endAt]);

  const { hint: scheduleConflictHint, checking: scheduleConflictChecking, fetchFailed: scheduleConflictFetchFailed } = useScheduleConflictPreview({
    siteId: event.site.id,
    scheduledAtIso,
    endAtIso,
    excludeEventId: event.id,
  });

  const isCompleted = !!event.completedAt;
  const moderationStatus = event.status ?? 'APPROVED';
  const isPending = moderationStatus === 'PENDING';

  function clearFieldError(key: CleanupEventFieldKey) {
    setFieldErrors((prev) => {
      if (!prev[key]) {
        return prev;
      }
      const next = { ...prev };
      delete next[key];
      return next;
    });
  }

  function handleFormFieldChange<K extends keyof CleanupEventFormValues>(
    key: K,
    value: CleanupEventFormValues[K],
  ) {
    switch (key) {
      case 'title':
        setTitle(value as string);
        break;
      case 'description':
        setDescription(value as string);
        break;
      case 'recurrenceRule':
        setRecurrenceRule(value as string);
        break;
      case 'scheduledAtLocal':
        setScheduledAt(new Date(value as string).toISOString());
        break;
      case 'endAtLocal':
        setEndAt(new Date(value as string).toISOString());
        break;
      case 'participantCount':
        setParticipantCount(value as number);
        break;
      default:
        break;
    }
  }

  function buildFormValues() {
    return {
      title,
      description,
      recurrenceRule,
      scheduledAtLocal: toDatetimeLocalField(scheduledAt),
      endAtLocal: toDatetimeLocalField(endAt),
      participantCount,
    };
  }

  const baselineEndAt = event.endAt
    ? new Date(event.endAt).toISOString()
    : defaultEndAtIsoFromScheduled(event.scheduledAt);

  const isDirty =
    title !== event.title ||
    description !== event.description ||
    (recurrenceRule || '') !== (event.recurrenceRule ?? '') ||
    scheduledAt !== event.scheduledAt ||
    endAt !== baselineEndAt ||
    (event.completedAt ?? '') !== completedAt ||
    participantCount !== event.participantCount;

  return {
    title,
    description,
    recurrenceRule,
    scheduledAt,
    endAt,
    completedAt,
    setCompletedAt,
    participantCount,
    fieldErrors,
    setFieldErrors,
    scheduleConflictHint,
    scheduleConflictChecking,
    scheduleConflictFetchFailed,
    scheduleConflictOverride,
    setScheduleConflictOverride,
    isCompleted,
    moderationStatus,
    isPending,
    clearFieldError,
    handleFormFieldChange,
    formValues: buildFormValues(),
    isDirty,
  };
}

export type EventDetailFormState = ReturnType<typeof useEventDetailForm>;
