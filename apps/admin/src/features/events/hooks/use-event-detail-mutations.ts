'use client';

import { useRouter } from 'next/navigation';
import { useCallback, useState } from 'react';
import { useTranslations } from 'next-intl';
import { useToast } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/api';
import type { CleanupEventDetail } from '@/features/events/data/events-adapter';
import { cleanupEventMutationMessage } from '@/features/events/lib/cleanup-events-api-messages';
import {
  validateCleanupEventDetailForm,
  validateDeclineReason,
} from '@/features/events/lib/admin-cleanup-event-validation';
import { toDatetimeLocalField } from '@/features/events/lib/event-admin-datetime';
import {
  parseDuplicateEventConflictFromApiError,
  type ConflictingEventInfo,
} from '@/features/events/lib/event-schedule-conflict-client';
import type { EventDetailFormState } from './use-event-detail-form';

export function useEventDetailMutations(event: CleanupEventDetail, form: EventDetailFormState) {
  const router = useRouter();
  const t = useTranslations('events');
  const tDetail = useTranslations('events.detail');
  const tCommon = useTranslations('common');
  const tErrors = useTranslations('errors');
  const [saving, setSaving] = useState(false);
  const { showToast, clearToast } = useToast();
  const [duplicateModal, setDuplicateModal] = useState<ConflictingEventInfo | null>(null);
  const [declineModalOpen, setDeclineModalOpen] = useState(false);
  const [declineReason, setDeclineReason] = useState('');
  const [declineReasonError, setDeclineReasonError] = useState<string | null>(null);

  const blockIfDirty = useCallback(() => {
    if (!form.isDirty) {
      return false;
    }
    showToast({
      tone: 'warning',
      title: tDetail('unsavedChangesTitle'),
      message: tDetail('unsavedChangesActionBlocked'),
    });
    return true;
  }, [form.isDirty, showToast, tDetail]);

  const {
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
    isCompleted,
    scheduleConflictHint,
    scheduleConflictOverride,
    clearFieldError,
  } = form;

  const saveUpdates = useCallback(async () => {
    if (scheduleConflictHint && !scheduleConflictOverride) {
      showToast({
        tone: 'warning',
        title: tDetail('scheduleConflictBlockedTitle'),
        message: tDetail('scheduleConflictBlockedMessage'),
      });
      return;
    }
    const errors = validateCleanupEventDetailForm({
      title,
      description,
      recurrenceRule,
      scheduledAtValue: scheduledAt,
      ...(isCompleted
        ? { completedAtLocal: completedAt.trim() ? toDatetimeLocalField(completedAt) : '' }
        : { endAtValue: endAt }),
      participantCount,
    });
    setFieldErrors(errors);
    if (Object.keys(errors).length > 0) {
      return;
    }

    setSaving(true);
    clearToast();
    const body: {
      title: string;
      description: string;
      recurrenceRule: string;
      scheduledAt: string;
      endAt?: string;
      participantCount: number;
      completedAt?: string | null;
    } = {
      title: title.trim() || t('create.defaultTitle'),
      description: description.trim(),
      recurrenceRule: recurrenceRule.trim(),
      scheduledAt: new Date(scheduledAt).toISOString(),
      participantCount,
    };
    if (!isCompleted) {
      body.endAt = new Date(endAt).toISOString();
    }
    if (event.completedAt) {
      body.completedAt = completedAt ? new Date(completedAt).toISOString() : null;
    }
    try {
      await adminBrowserFetch(`/admin/cleanup-events/${event.id}`, {
        method: 'PATCH',
        body,
      });
      showToast({ tone: 'success', title: tCommon('saved'), message: tDetail('eventUpdatedMessage') });
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
        message: cleanupEventMutationMessage(e, tCommon('updateFailed'), (key) => tErrors(key)),
      });
    } finally {
      setSaving(false);
    }
  }, [
    title,
    description,
    recurrenceRule,
    scheduledAt,
    endAt,
    completedAt,
    participantCount,
    isCompleted,
    event.id,
    event.completedAt,
    router,
    setFieldErrors,
    t,
    tDetail,
    tCommon,
    tErrors,
    clearToast,
    showToast,
    scheduleConflictHint,
    scheduleConflictOverride,
  ]);

  const approve = useCallback(async () => {
    if (blockIfDirty()) return;
    setSaving(true);
    clearToast();
    try {
      await adminBrowserFetch(`/admin/cleanup-events/${event.id}`, {
        method: 'PATCH',
        body: { status: 'APPROVED' },
      });
      showToast({ tone: 'success', title: tDetail('eventApprovedTitle'), message: tDetail('eventApprovedMessage') });
      router.refresh();
    } catch (e) {
      showToast({
        tone: 'warning',
        title: tCommon('errorGeneric'),
        message: cleanupEventMutationMessage(e, tCommon('actionFailed'), (key) => tErrors(key)),
      });
    } finally {
      setSaving(false);
    }
  }, [blockIfDirty, event.id, router, tCommon, tDetail, tErrors, clearToast, showToast]);

  const openDeclineModal = useCallback(() => {
    if (blockIfDirty()) return;
    setDeclineReason('');
    setDeclineReasonError(null);
    setDeclineModalOpen(true);
  }, [blockIfDirty]);

  const closeDeclineModal = useCallback(() => {
    setDeclineModalOpen(false);
    setDeclineReason('');
    setDeclineReasonError(null);
  }, []);

  const submitDecline = useCallback(async () => {
    const reasonErr = validateDeclineReason(declineReason);
    setDeclineReasonError(reasonErr);
    if (reasonErr) {
      return;
    }
    setSaving(true);
    clearToast();
    try {
      await adminBrowserFetch(`/admin/cleanup-events/${event.id}`, {
        method: 'PATCH',
        body: { status: 'DECLINED', declineReason: declineReason.trim() },
      });
      closeDeclineModal();
      showToast({ tone: 'success', title: tDetail('eventDeclinedTitle'), message: tDetail('eventDeclinedMessage') });
      router.refresh();
    } catch (e) {
      showToast({
        tone: 'warning',
        title: tCommon('errorGeneric'),
        message: cleanupEventMutationMessage(e, tCommon('actionFailed'), (key) => tErrors(key)),
      });
    } finally {
      setSaving(false);
    }
  }, [declineReason, event.id, router, closeDeclineModal, tCommon, tDetail, tErrors, clearToast, showToast]);

  const returnToPending = useCallback(async () => {
    if (blockIfDirty()) return;
    setSaving(true);
    clearToast();
    try {
      await adminBrowserFetch(`/admin/cleanup-events/${event.id}`, {
        method: 'PATCH',
        body: { status: 'PENDING' },
      });
      showToast({
        tone: 'success',
        title: tDetail('returnToPendingTitle'),
        message: tDetail('returnToPendingMessage'),
      });
      router.refresh();
    } catch (e) {
      showToast({
        tone: 'warning',
        title: tCommon('errorGeneric'),
        message: cleanupEventMutationMessage(e, tCommon('actionFailed'), (key) => tErrors(key)),
      });
    } finally {
      setSaving(false);
    }
  }, [blockIfDirty, event.id, router, tCommon, tDetail, tErrors, clearToast, showToast]);

  const patchLifecycle = useCallback(
    async (lifecycleStatus: 'IN_PROGRESS' | 'CANCELLED' | 'COMPLETED', options?: { completedAt?: string }) => {
      if (blockIfDirty()) return;
      setSaving(true);
      clearToast();
      try {
        const body: { lifecycleStatus: string; completedAt?: string } = { lifecycleStatus };
        if (options?.completedAt) {
          body.completedAt = options.completedAt;
        }
        await adminBrowserFetch(`/admin/cleanup-events/${event.id}`, {
          method: 'PATCH',
          body,
        });
        showToast({
          tone: 'success',
          title: tDetail('lifecycleUpdatedTitle'),
          message: tDetail('lifecycleUpdatedMessage', { status: lifecycleStatus }),
        });
        router.refresh();
      } catch (e) {
        showToast({
          tone: 'warning',
          title: tCommon('errorGeneric'),
          message: cleanupEventMutationMessage(e, tCommon('actionFailed'), (key) => tErrors(key)),
        });
      } finally {
        setSaving(false);
      }
    },
    [blockIfDirty, event.id, router, tCommon, tDetail, tErrors, clearToast, showToast],
  );

  const markComplete = useCallback(async () => {
    if (blockIfDirty()) return;
    const previousCompletedAt = completedAt;
    const now = new Date().toISOString();
    setCompletedAt(now);
    setSaving(true);
    clearToast();
    try {
      await adminBrowserFetch(`/admin/cleanup-events/${event.id}`, {
        method: 'PATCH',
        body: {
          completedAt: now,
          participantCount,
        },
      });
      showToast({ tone: 'success', title: tDetail('eventCompletedTitle'), message: tDetail('eventCompletedMessage') });
      router.refresh();
    } catch (e) {
      setCompletedAt(previousCompletedAt);
      showToast({
        tone: 'warning',
        title: tCommon('errorGeneric'),
        message: cleanupEventMutationMessage(e, tCommon('updateFailed'), (key) => tErrors(key)),
      });
    } finally {
      setSaving(false);
    }
  }, [blockIfDirty, completedAt, event.id, participantCount, router, setCompletedAt, tCommon, tDetail, tErrors, clearToast, showToast]);

  return {
    saving,
    duplicateModal,
    setDuplicateModal,
    declineModalOpen,
    declineReason,
    setDeclineReason,
    declineReasonError,
    setDeclineReasonError,
    saveUpdates,
    approve,
    openDeclineModal,
    closeDeclineModal,
    submitDecline,
    returnToPending,
    patchLifecycle,
    markComplete,
    fieldErrors,
    clearFieldError,
  };
}

export type EventDetailMutationsState = ReturnType<typeof useEventDetailMutations>;
