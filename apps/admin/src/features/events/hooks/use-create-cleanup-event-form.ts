'use client';

import { useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { useToast } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/api';
import { cleanupEventMutationMessage } from '@/features/events/lib/cleanup-events-api-messages';
import {
  type CleanupEventFieldErrors,
  type CleanupEventFieldKey,
  validateCleanupEventForm,
} from '@/features/events/lib/admin-cleanup-event-validation';
import {
  defaultCreateScheduledAtLocal,
  toDatetimeLocalFromDate,
} from '@/features/events/lib/event-admin-datetime';
import {
  parseDuplicateEventConflictFromApiError,
  type ConflictingEventInfo,
} from '@/features/events/lib/event-schedule-conflict-client';
import { useScheduleConflictPreview } from '@/features/events/lib/use-schedule-conflict-preview';
import type { CleanupEventFormValues } from '@/features/events/components/cleanup-event-form-fields';

function defaultEndAtLocal(scheduledAtLocal: string): string {
  const parsed = new Date(scheduledAtLocal);
  if (Number.isNaN(parsed.getTime())) {
    return scheduledAtLocal;
  }
  const end = new Date(parsed);
  end.setTime(end.getTime() + 3 * 60 * 60 * 1000);
  return toDatetimeLocalFromDate(end);
}

export function useCreateCleanupEventForm(siteId: string) {
  const router = useRouter();
  const t = useTranslations('events');
  const tCommon = useTranslations('common');
  const tErrors = useTranslations('errors');
  const defaultScheduled = defaultCreateScheduledAtLocal();

  const [title, setTitle] = useState(() => t('create.defaultTitle'));
  const [description, setDescription] = useState('');
  const [recurrenceRule, setRecurrenceRule] = useState('');
  const [scheduledAt, setScheduledAt] = useState(defaultScheduled);
  const [endAt, setEndAt] = useState(() => defaultEndAtLocal(defaultScheduled));
  const [participantCount, setParticipantCount] = useState(0);
  const [createAsPending, setCreateAsPending] = useState(false);
  const [saving, setSaving] = useState(false);
  const { showToast, clearToast } = useToast();
  const [fieldErrors, setFieldErrors] = useState<CleanupEventFieldErrors>({});
  const [duplicateModal, setDuplicateModal] = useState<ConflictingEventInfo | null>(null);

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

  const { hint: scheduleConflictHint, checking: scheduleConflictChecking } = useScheduleConflictPreview({
    siteId,
    scheduledAtIso,
    endAtIso,
  });

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
        setScheduledAt(value as string);
        break;
      case 'endAtLocal':
        setEndAt(value as string);
        break;
      case 'participantCount':
        setParticipantCount(value as number);
        break;
      default:
        break;
    }
  }

  const formValues: CleanupEventFormValues = {
    title,
    description,
    recurrenceRule,
    scheduledAtLocal: scheduledAt,
    endAtLocal: endAt,
    participantCount,
  };

  async function submit() {
    const errors = validateCleanupEventForm({
      title,
      description,
      recurrenceRule,
      scheduledAtRaw: scheduledAt,
      endAtRaw: endAt,
      participantCount,
    });
    setFieldErrors(errors);
    if (Object.keys(errors).length > 0) {
      return;
    }

    setSaving(true);
    clearToast();
    try {
      const created = await adminBrowserFetch<{ id: string }>('/admin/cleanup-events', {
        method: 'POST',
        body: {
          siteId,
          title: title.trim() || t('create.defaultTitle'),
          description: description.trim(),
          ...(recurrenceRule.trim() ? { recurrenceRule: recurrenceRule.trim() } : {}),
          scheduledAt: new Date(scheduledAt).toISOString(),
          endAt: new Date(endAt).toISOString(),
          participantCount,
          ...(createAsPending ? { status: 'PENDING' } : {}),
        },
      });
      showToast({
        tone: 'success',
        title: t('create.eventCreatedTitle'),
        message: t('create.eventCreatedMessage'),
      });
      router.push(`/dashboard/events/${created.id}`);
      router.refresh();
    } catch (e) {
      const duplicate = parseDuplicateEventConflictFromApiError(e);
      if (duplicate) {
        setDuplicateModal(duplicate);
        return;
      }
      showToast({
        tone: 'warning',
        title: tCommon('errorGeneric'),
        message: cleanupEventMutationMessage(e, tCommon('saveFailed'), (key) => tErrors(key)),
      });
    } finally {
      setSaving(false);
    }
  }

  return {
    formValues,
    fieldErrors,
    createAsPending,
    setCreateAsPending,
    saving,
    duplicateModal,
    setDuplicateModal,
    scheduleConflictHint,
    scheduleConflictChecking,
    clearFieldError,
    handleFormFieldChange,
    submit,
  };
}

export type CreateCleanupEventFormState = ReturnType<typeof useCreateCleanupEventForm>;
