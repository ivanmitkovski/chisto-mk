'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useEffect, useMemo, useRef, useState } from 'react';
import { Button, Icon, Snack, type SnackState } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/admin-browser-api';
import { cleanupEventMutationMessage } from '@/features/events/lib/cleanup-events-api-messages';
import {
  type CleanupEventFieldErrors,
  validateCleanupEventForm,
} from '@/features/events/lib/admin-cleanup-event-validation';
import { parseDuplicateEventConflictFromApiError } from '@/features/events/lib/event-schedule-conflict-client';
import { useScheduleConflictPreview } from '@/features/events/lib/use-schedule-conflict-preview';
import styles from './create-event-form.module.css';

function toDatetimeLocal(date: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

type CreateEventFormProps = {
  siteId: string;
};

export function CreateEventForm({ siteId }: CreateEventFormProps) {
  const router = useRouter();
  const defaultDate = new Date();
  defaultDate.setDate(defaultDate.getDate() + 7);
  defaultDate.setHours(10, 0, 0, 0);
  const defaultEndDate = new Date(defaultDate);
  defaultEndDate.setDate(defaultEndDate.getDate() + 1);

  const [title, setTitle] = useState('Cleanup event');
  const [description, setDescription] = useState('');
  const [recurrenceRule, setRecurrenceRule] = useState('');
  const [scheduledAt, setScheduledAt] = useState(toDatetimeLocal(defaultDate));
  const [endAt, setEndAt] = useState(toDatetimeLocal(defaultEndDate));
  const [participantCount, setParticipantCount] = useState(0);
  const [createAsPending, setCreateAsPending] = useState(false);
  const [saving, setSaving] = useState(false);
  const [snack, setSnack] = useState<SnackState | null>(null);
  const [fieldErrors, setFieldErrors] = useState<CleanupEventFieldErrors>({});
  const [duplicateModal, setDuplicateModal] = useState<{
    id: string;
    title: string;
    scheduledAt: string;
  } | null>(null);
  const duplicateModalPrimaryRef = useRef<HTMLButtonElement>(null);

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

  useEffect(() => {
    if (!duplicateModal) {
      return;
    }
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        setDuplicateModal(null);
      }
    };
    document.addEventListener('keydown', onKeyDown);
    const id = requestAnimationFrame(() => {
      duplicateModalPrimaryRef.current?.focus();
    });
    return () => {
      document.removeEventListener('keydown', onKeyDown);
      cancelAnimationFrame(id);
    };
  }, [duplicateModal]);

  function clearFieldError(key: keyof CleanupEventFieldErrors) {
    setFieldErrors((prev) => {
      if (!prev[key]) {
        return prev;
      }
      const next = { ...prev };
      delete next[key];
      return next;
    });
  }

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
    setSnack(null);
    try {
      const created = await adminBrowserFetch<{ id: string }>('/admin/cleanup-events', {
        method: 'POST',
        body: {
          siteId,
          title: title.trim() || 'Cleanup event',
          description: description.trim(),
          ...(recurrenceRule.trim() ? { recurrenceRule: recurrenceRule.trim() } : {}),
          scheduledAt: new Date(scheduledAt).toISOString(),
          endAt: new Date(endAt).toISOString(),
          participantCount,
          ...(createAsPending ? { status: 'PENDING' } : {}),
        },
      });
      setSnack({
        tone: 'success',
        title: 'Event created',
        message: 'Cleanup event has been created.',
      });
      router.push(`/dashboard/events/${created.id}`);
      router.refresh();
    } catch (e) {
      const duplicate = parseDuplicateEventConflictFromApiError(e);
      if (duplicate) {
        setDuplicateModal(duplicate);
        return;
      }
      setSnack({
        tone: 'warning',
        title: 'Error',
        message: cleanupEventMutationMessage(e, 'Create failed'),
      });
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className={styles.layout}>
      <Link href="/dashboard/events" className={styles.backLink}>
        <Icon name="chevron-left" size={16} />
        Back to events
      </Link>

      <section className={styles.sectionCard}>
        <span className={styles.sectionLabel}>New cleanup event</span>
        <p className={styles.hint}>
          Create a cleanup event for site <code className={styles.siteId}>{siteId}</code>.
          <Link href={`/dashboard/sites/${siteId}`} className={styles.siteLink}>
            View site
          </Link>
        </p>
        <div className={styles.form}>
          <label className={styles.field} htmlFor="create-event-title">
            <span className={styles.fieldLabel}>Title</span>
            <input
              id="create-event-title"
              type="text"
              value={title}
              onChange={(e) => {
                setTitle(e.target.value);
                clearFieldError('title');
              }}
              className={styles.input}
              maxLength={200}
              aria-invalid={fieldErrors.title ? true : undefined}
              aria-describedby={fieldErrors.title ? 'create-event-title-err' : undefined}
            />
            {fieldErrors.title ? (
              <span id="create-event-title-err" className={styles.fieldError} role="alert">
                {fieldErrors.title}
              </span>
            ) : null}
          </label>
          <label className={styles.field} htmlFor="create-event-description">
            <span className={styles.fieldLabel}>Description</span>
            <textarea
              id="create-event-description"
              value={description}
              onChange={(e) => {
                setDescription(e.target.value);
                clearFieldError('description');
              }}
              className={styles.input}
              rows={4}
              maxLength={10000}
              aria-invalid={fieldErrors.description ? true : undefined}
              aria-describedby={fieldErrors.description ? 'create-event-description-err' : undefined}
            />
            {fieldErrors.description ? (
              <span id="create-event-description-err" className={styles.fieldError} role="alert">
                {fieldErrors.description}
              </span>
            ) : null}
          </label>
          <label className={styles.field} htmlFor="create-event-rrule">
            <span className={styles.fieldLabel}>Recurrence (optional RFC 5545 RRULE)</span>
            <textarea
              id="create-event-rrule"
              value={recurrenceRule}
              onChange={(e) => {
                setRecurrenceRule(e.target.value);
                clearFieldError('recurrenceRule');
              }}
              className={styles.input}
              rows={2}
              placeholder="FREQ=WEEKLY;BYDAY=SA;COUNT=8"
              maxLength={2048}
              aria-invalid={fieldErrors.recurrenceRule ? true : undefined}
              aria-describedby={fieldErrors.recurrenceRule ? 'create-event-rrule-err' : undefined}
            />
            <span className={styles.fieldHint}>
              Stored on this event for reference; admin create does not expand a series in the database.
            </span>
            {fieldErrors.recurrenceRule ? (
              <span id="create-event-rrule-err" className={styles.fieldError} role="alert">
                {fieldErrors.recurrenceRule}
              </span>
            ) : null}
          </label>
          <label className={styles.field} htmlFor="create-event-scheduled">
            <span className={styles.fieldLabel}>Start date & time</span>
            <input
              id="create-event-scheduled"
              type="datetime-local"
              value={scheduledAt}
              onChange={(e) => {
                setScheduledAt(e.target.value);
                clearFieldError('scheduledAt');
              }}
              className={styles.input}
              aria-invalid={fieldErrors.scheduledAt ? true : undefined}
              aria-describedby={fieldErrors.scheduledAt ? 'create-event-scheduled-err' : undefined}
            />
            {fieldErrors.scheduledAt ? (
              <span id="create-event-scheduled-err" className={styles.fieldError} role="alert">
                {fieldErrors.scheduledAt}
              </span>
            ) : null}
          </label>
          <label className={styles.field} htmlFor="create-event-end">
            <span className={styles.fieldLabel}>End date & time</span>
            <span className={styles.fieldHint}>Must be on the same calendar day as the start, by 23:59 at the latest.</span>
            <input
              id="create-event-end"
              type="datetime-local"
              value={endAt}
              onChange={(e) => {
                setEndAt(e.target.value);
                clearFieldError('endAt');
              }}
              className={styles.input}
              aria-invalid={fieldErrors.endAt ? true : undefined}
              aria-describedby={fieldErrors.endAt ? 'create-event-end-err' : undefined}
            />
            {fieldErrors.endAt ? (
              <span id="create-event-end-err" className={styles.fieldError} role="alert">
                {fieldErrors.endAt}
              </span>
            ) : null}
          </label>
          {scheduleConflictHint ? (
            <div className={styles.conflictBanner} role="status">
              {scheduleConflictChecking ? (
                'Checking schedule…'
              ) : (
                <>
                  Another event may overlap this time at this site:{' '}
                  <strong>{scheduleConflictHint.title}</strong> (
                  {new Date(scheduleConflictHint.scheduledAt).toLocaleString(undefined, {
                    dateStyle: 'medium',
                    timeStyle: 'short',
                  })}
                  ).{' '}
                  <Link href={`/dashboard/events/${scheduleConflictHint.id}`}>Open event</Link>.
                </>
              )}
            </div>
          ) : null}
          <label className={styles.fieldCheck}>
            <input
              type="checkbox"
              checked={createAsPending}
              onChange={(e) => setCreateAsPending(e.target.checked)}
            />
            <span>Create as pending (simulate user submission, requires approval)</span>
          </label>
          <label className={styles.field} htmlFor="create-event-participants">
            <span className={styles.fieldLabel}>Initial participant count</span>
            <input
              id="create-event-participants"
              type="number"
              min={0}
              value={participantCount}
              onChange={(e) => {
                setParticipantCount(Math.max(0, parseInt(e.target.value, 10) || 0));
                clearFieldError('participantCount');
              }}
              className={styles.input}
              aria-invalid={fieldErrors.participantCount ? true : undefined}
              aria-describedby={fieldErrors.participantCount ? 'create-event-participants-err' : undefined}
            />
            {fieldErrors.participantCount ? (
              <span id="create-event-participants-err" className={styles.fieldError} role="alert">
                {fieldErrors.participantCount}
              </span>
            ) : null}
          </label>
          <div className={styles.actions}>
            <Button onClick={() => void submit()} disabled={saving}>
              {saving ? 'Creating…' : 'Create event'}
            </Button>
            <Link href="/dashboard/events" className={styles.cancelLink}>
              Cancel
            </Link>
          </div>
        </div>
      </section>

      <Snack snack={snack} onClose={() => setSnack(null)} />

      {duplicateModal ? (
        <div className={styles.modalBackdrop} role="presentation" onClick={() => setDuplicateModal(null)}>
          <div
            className={styles.modalCard}
            role="dialog"
            aria-modal="true"
            aria-labelledby="duplicate-event-modal-title"
            aria-describedby="duplicate-event-modal-desc"
            onClick={(ev) => ev.stopPropagation()}
          >
            <h2 id="duplicate-event-modal-title" className={styles.modalTitle}>
              Schedule conflict
            </h2>
            <p id="duplicate-event-modal-desc" className={styles.modalBody}>
              {duplicateModal.title} is already scheduled for{' '}
              {new Date(duplicateModal.scheduledAt).toLocaleString(undefined, {
                dateStyle: 'medium',
                timeStyle: 'short',
              })}
              . Adjust the time or open the existing event.
            </p>
            <div className={styles.modalActions}>
              <Button
                ref={duplicateModalPrimaryRef}
                type="button"
                onClick={() => void router.push(`/dashboard/events/${duplicateModal.id}`)}
              >
                Open event
              </Button>
              <Button type="button" variant="outline" onClick={() => setDuplicateModal(null)}>
                Change time
              </Button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
