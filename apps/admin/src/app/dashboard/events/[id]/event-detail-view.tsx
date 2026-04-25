'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useEffect, useMemo, useRef, useState } from 'react';
import { Button, Icon, Input, Snack, type SnackState } from '@/components/ui';
import { useFocusTrap } from '@/lib/use-focus-trap';
import { adminBrowserFetch } from '@/lib/admin-browser-api';
import { cleanupEventMutationMessage } from '@/features/events/lib/cleanup-events-api-messages';
import {
  type CleanupEventFieldErrors,
  validateCleanupEventDetailForm,
  validateDeclineReason,
} from '@/features/events/lib/admin-cleanup-event-validation';
import type { CleanupEventDetail } from '@/features/events/data/events-adapter';
import { parseDuplicateEventConflictFromApiError } from '@/features/events/lib/event-schedule-conflict-client';
import { useScheduleConflictPreview } from '@/features/events/lib/use-schedule-conflict-preview';
import styles from './event-detail.module.css';
import { EventDetailInsights } from './event-detail-insights';

/** North Macedonia schedule display for admin; fixed TZ avoids SSR/client hydration mismatches. */
const EVENT_ADMIN_TZ = 'Europe/Skopje';

function formatEventAdminDateTime(iso: string): string {
  return new Date(iso).toLocaleString('en-GB', {
    timeZone: EVENT_ADMIN_TZ,
    dateStyle: 'medium',
    timeStyle: 'short',
  });
}

/** `datetime-local` value in [EVENT_ADMIN_TZ] wall time (stable across Node SSR and browsers). */
function toDatetimeLocalField(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) {
    return '';
  }
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: EVENT_ADMIN_TZ,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).formatToParts(d);
  const v = (t: Intl.DateTimeFormatPartTypes) => parts.find((p) => p.type === t)?.value ?? '00';
  return `${v('year')}-${v('month')}-${v('day')}T${v('hour')}:${v('minute')}`;
}

type EventDetailViewProps = {
  event: CleanupEventDetail;
  canWriteCleanupEvents: boolean;
};

export function EventDetailView({ event, canWriteCleanupEvents }: EventDetailViewProps) {
  const router = useRouter();
  const [title, setTitle] = useState(event.title);
  const [description, setDescription] = useState(event.description);
  const [recurrenceRule, setRecurrenceRule] = useState(event.recurrenceRule ?? '');
  const [scheduledAt, setScheduledAt] = useState(event.scheduledAt);
  const [endAt, setEndAt] = useState(() => {
    if (event.endAt) {
      return new Date(event.endAt).toISOString();
    }
    const next = new Date(event.scheduledAt);
    next.setTime(next.getTime() + 3 * 60 * 60 * 1000);
    return next.toISOString();
  });
  const [completedAt, setCompletedAt] = useState(event.completedAt ?? '');
  const [participantCount, setParticipantCount] = useState(event.participantCount);
  const [saving, setSaving] = useState(false);
  const [snack, setSnack] = useState<SnackState | null>(null);
  const [fieldErrors, setFieldErrors] = useState<CleanupEventFieldErrors>({});
  const [duplicateModal, setDuplicateModal] = useState<{
    id: string;
    title: string;
    scheduledAt: string;
  } | null>(null);
  const duplicateModalPrimaryRef = useRef<HTMLButtonElement>(null);
  const duplicateModalCardRef = useRef<HTMLDivElement>(null);
  const [declineModalOpen, setDeclineModalOpen] = useState(false);
  const [declineReason, setDeclineReason] = useState('');
  const [declineReasonError, setDeclineReasonError] = useState<string | null>(null);
  const declineReasonTextareaRef = useRef<HTMLTextAreaElement>(null);
  const declineModalCardRef = useRef<HTMLDivElement>(null);

  const site = event.site;

  useEffect(() => {
    setTitle(event.title);
    setDescription(event.description);
    setRecurrenceRule(event.recurrenceRule ?? '');
    setScheduledAt(event.scheduledAt);
    if (event.endAt) {
      setEndAt(new Date(event.endAt).toISOString());
    } else {
      const next = new Date(event.scheduledAt);
      next.setTime(next.getTime() + 3 * 60 * 60 * 1000);
      setEndAt(next.toISOString());
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

  useFocusTrap(!!duplicateModal, duplicateModalCardRef);
  useFocusTrap(declineModalOpen, declineModalCardRef);

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
    siteId: site.id,
    scheduledAtIso,
    endAtIso,
    excludeEventId: event.id,
  });

  const isCompleted = !!event.completedAt;
  const moderationStatus = (event as { status?: string }).status ?? 'APPROVED';
  const isPending = moderationStatus === 'PENDING';

  const gm = `https://www.google.com/maps?q=${site.latitude},${site.longitude}`;
  const am = `https://maps.apple.com/?q=${site.latitude},${site.longitude}`;

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

  useEffect(() => {
    if (!declineModalOpen) {
      return;
    }
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        setDeclineModalOpen(false);
        setDeclineReason('');
        setDeclineReasonError(null);
      }
    };
    document.addEventListener('keydown', onKeyDown);
    const id = requestAnimationFrame(() => {
      declineReasonTextareaRef.current?.focus();
    });
    return () => {
      document.removeEventListener('keydown', onKeyDown);
      cancelAnimationFrame(id);
    };
  }, [declineModalOpen]);

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

  async function saveUpdates() {
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
    setSnack(null);
    const body: {
      title: string;
      description: string;
      recurrenceRule: string;
      scheduledAt: string;
      endAt?: string;
      participantCount: number;
      completedAt?: string | null;
    } = {
      title: title.trim() || 'Cleanup event',
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
      setSnack({ tone: 'success', title: 'Saved', message: 'Event updated.' });
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
        message: cleanupEventMutationMessage(e, 'Update failed'),
      });
    } finally {
      setSaving(false);
    }
  }

  async function approve() {
    setSaving(true);
    setSnack(null);
    try {
      await adminBrowserFetch(`/admin/cleanup-events/${event.id}`, {
        method: 'PATCH',
        body: { status: 'APPROVED' },
      });
      setSnack({ tone: 'success', title: 'Event approved', message: 'The event is now visible to users.' });
      router.refresh();
    } catch (e) {
      setSnack({
        tone: 'warning',
        title: 'Error',
        message: cleanupEventMutationMessage(e, 'Approve failed'),
      });
    } finally {
      setSaving(false);
    }
  }

  function openDeclineModal() {
    setDeclineReason('');
    setDeclineReasonError(null);
    setDeclineModalOpen(true);
  }

  async function submitDecline() {
    const reasonErr = validateDeclineReason(declineReason);
    setDeclineReasonError(reasonErr);
    if (reasonErr) {
      return;
    }
    setSaving(true);
    setSnack(null);
    try {
      await adminBrowserFetch(`/admin/cleanup-events/${event.id}`, {
        method: 'PATCH',
        body: { status: 'DECLINED', declineReason: declineReason.trim() },
      });
      setDeclineModalOpen(false);
      setDeclineReason('');
      setSnack({ tone: 'success', title: 'Event declined', message: 'The event has been declined.' });
      router.refresh();
    } catch (e) {
      setSnack({
        tone: 'warning',
        title: 'Error',
        message: cleanupEventMutationMessage(e, 'Decline failed'),
      });
    } finally {
      setSaving(false);
    }
  }

  async function markComplete() {
    const now = new Date().toISOString();
    setCompletedAt(now);
    setSaving(true);
    setSnack(null);
    try {
      await adminBrowserFetch(`/admin/cleanup-events/${event.id}`, {
        method: 'PATCH',
        body: {
          completedAt: now,
          participantCount,
        },
      });
      setSnack({ tone: 'success', title: 'Event completed', message: 'Cleanup event marked as completed.' });
      router.refresh();
    } catch (e) {
      setSnack({
        tone: 'warning',
        title: 'Error',
        message: cleanupEventMutationMessage(e, 'Update failed'),
      });
    } finally {
      setSaving(false);
    }
  }

  const readOnly = !canWriteCleanupEvents;

  return (
    <div className={styles.layout}>
      <Link href="/dashboard/events" className={styles.backLink}>
        <Icon name="chevron-left" size={16} />
        Back to events
      </Link>

      <EventDetailInsights
        eventId={event.id}
        lifecycleStatus={event.lifecycleStatus}
        canWrite={canWriteCleanupEvents}
      />

      {readOnly ? (
        <div className={styles.readOnlyBanner} role="status">
          You are viewing this event with read-only access. Creating or editing cleanup events requires an admin
          role.
        </div>
      ) : null}

      <section className={styles.sectionCard}>
        <span className={styles.sectionLabel}>Event status</span>
        <div className={styles.statusRow}>
          <span className={isCompleted ? styles.statusCompleted : styles.statusUpcoming}>
            {isCompleted ? 'Completed' : 'Upcoming'}
          </span>
          <span className={styles.lifecyclePill}>{event.lifecycleStatus}</span>
          <span
            className={
              moderationStatus === 'PENDING'
                ? styles.moderationPending
                : moderationStatus === 'DECLINED'
                  ? styles.moderationDeclined
                  : styles.moderationApproved
            }
          >
            {moderationStatus}
          </span>
        </div>
        <h1 className={styles.eventTitle}>{event.title}</h1>
        {event.description ? (
          <p className={styles.eventDescription}>{event.description}</p>
        ) : null}
        {event.recurrenceRule ? (
          <p className={styles.recurrenceReadonly}>
            <span className={styles.metaLabel}>Recurrence</span>
            <code className={styles.rruleCode}>{event.recurrenceRule}</code>
          </p>
        ) : null}
        <div className={styles.metaRow}>
          <div className={styles.metaItem}>
            <span className={styles.metaLabel}>Scheduled</span>
            <span className={styles.metaValue}>{formatEventAdminDateTime(event.scheduledAt)}</span>
          </div>
          {event.completedAt && (
            <div className={styles.metaItem}>
              <span className={styles.metaLabel}>Completed</span>
              <span className={styles.metaValue}>{formatEventAdminDateTime(event.completedAt)}</span>
            </div>
          )}
          <div className={styles.metaItem}>
            <span className={styles.metaLabel}>Participants</span>
            <span className={styles.metaValue}>{event.participantCount}</span>
          </div>
        </div>
      </section>

      <section className={styles.sectionCard}>
        <span className={styles.sectionLabel}>Site location</span>
        <p className={styles.coordsValue}>
          {site.latitude.toFixed(6)}, {site.longitude.toFixed(6)}
        </p>
        {site.description ? <p className={styles.description}>{site.description}</p> : null}
        <div className={styles.mapLinks}>
          <a href={gm} target="_blank" rel="noopener noreferrer" className={styles.mapBtn}>
            Open in Google Maps
          </a>
          <a href={am} target="_blank" rel="noopener noreferrer" className={styles.mapBtn}>
            Open in Apple Maps
          </a>
        </div>
        <Link href={`/dashboard/sites/${site.id}`} className={styles.siteLink}>
          View site details
        </Link>
      </section>

      <section className={styles.sectionCard}>
        <span className={styles.sectionLabel}>Moderation</span>
        {isPending && canWriteCleanupEvents && (
          <div className={styles.approveDeclineBar}>
            <p className={styles.approveDeclineHint}>
              This event was created by a user and awaits your review. Approve to make it visible to participants, or
              decline to reject it.
            </p>
            <div className={styles.approveDeclineActions}>
              <Button onClick={() => void approve()} isLoading={saving}>
                <Icon name="check" size={14} />
                Approve
              </Button>
              <Button variant="outline" onClick={openDeclineModal} disabled={saving} className={styles.declineBtn}>
                Decline
              </Button>
            </div>
          </div>
        )}
        {isPending && !canWriteCleanupEvents && (
          <p className={styles.approveDeclineHint} role="note">
            This event is pending approval. Only an admin can approve or decline it.
          </p>
        )}
        <p className={styles.moderationHint}>
          {isPending ? 'You can also edit details before approving.' : 'Edit event details. Changes are saved when you click Save.'}
        </p>
        <div className={styles.form}>
          <label className={styles.field} htmlFor="detail-event-title">
            <span className={styles.fieldLabel}>Title</span>
            <input
              id="detail-event-title"
              type="text"
              value={title}
              disabled={readOnly}
              onChange={(e) => {
                setTitle(e.target.value);
                clearFieldError('title');
              }}
              className={styles.input}
              maxLength={200}
              aria-invalid={fieldErrors.title ? true : undefined}
              aria-describedby={fieldErrors.title ? 'detail-event-title-err' : undefined}
            />
            {fieldErrors.title ? (
              <span id="detail-event-title-err" className={styles.fieldError} role="alert">
                {fieldErrors.title}
              </span>
            ) : null}
          </label>
          <label className={styles.field} htmlFor="detail-event-description">
            <span className={styles.fieldLabel}>Description</span>
            <textarea
              id="detail-event-description"
              value={description}
              disabled={readOnly}
              onChange={(e) => {
                setDescription(e.target.value);
                clearFieldError('description');
              }}
              className={styles.textarea}
              rows={4}
              maxLength={10000}
              aria-invalid={fieldErrors.description ? true : undefined}
              aria-describedby={fieldErrors.description ? 'detail-event-description-err' : undefined}
            />
            {fieldErrors.description ? (
              <span id="detail-event-description-err" className={styles.fieldError} role="alert">
                {fieldErrors.description}
              </span>
            ) : null}
          </label>
          <label className={styles.field} htmlFor="detail-event-rrule">
            <span className={styles.fieldLabel}>Recurrence (RRULE, optional)</span>
            <textarea
              id="detail-event-rrule"
              value={recurrenceRule}
              disabled={readOnly}
              onChange={(e) => {
                setRecurrenceRule(e.target.value);
                clearFieldError('recurrenceRule');
              }}
              className={styles.textarea}
              rows={2}
              placeholder="Leave empty to clear"
              maxLength={2048}
              aria-invalid={fieldErrors.recurrenceRule ? true : undefined}
              aria-describedby={fieldErrors.recurrenceRule ? 'detail-event-rrule-err' : undefined}
            />
            <span className={styles.fieldHint}>Clear the field and save to remove recurrence metadata.</span>
            {fieldErrors.recurrenceRule ? (
              <span id="detail-event-rrule-err" className={styles.fieldError} role="alert">
                {fieldErrors.recurrenceRule}
              </span>
            ) : null}
          </label>
          <label className={styles.field} htmlFor="detail-event-scheduled">
            <span className={styles.fieldLabel}>Start date & time</span>
            <input
              id="detail-event-scheduled"
              type="datetime-local"
              value={toDatetimeLocalField(scheduledAt)}
              disabled={readOnly}
              onChange={(e) => {
                setScheduledAt(new Date(e.target.value).toISOString());
                clearFieldError('scheduledAt');
              }}
              className={styles.input}
              aria-invalid={fieldErrors.scheduledAt ? true : undefined}
              aria-describedby={fieldErrors.scheduledAt ? 'detail-event-scheduled-err' : undefined}
            />
            {fieldErrors.scheduledAt ? (
              <span id="detail-event-scheduled-err" className={styles.fieldError} role="alert">
                {fieldErrors.scheduledAt}
              </span>
            ) : null}
          </label>
          {!isCompleted ? (
            <label className={styles.field} htmlFor="detail-event-end">
              <span className={styles.fieldLabel}>End date & time</span>
              <span className={styles.fieldHint}>Must be on the same calendar day as the start, by 23:59 at the latest.</span>
              <input
                id="detail-event-end"
                type="datetime-local"
                value={toDatetimeLocalField(endAt)}
                disabled={readOnly}
                onChange={(e) => {
                  setEndAt(new Date(e.target.value).toISOString());
                  clearFieldError('endAt');
                }}
                className={styles.input}
                aria-invalid={fieldErrors.endAt ? true : undefined}
                aria-describedby={fieldErrors.endAt ? 'detail-event-end-err' : undefined}
              />
              {fieldErrors.endAt ? (
                <span id="detail-event-end-err" className={styles.fieldError} role="alert">
                  {fieldErrors.endAt}
                </span>
              ) : null}
            </label>
          ) : null}
          {scheduleConflictHint ? (
            <div className={styles.conflictBanner} role="status">
              {scheduleConflictChecking ? (
                'Checking schedule…'
              ) : (
                <>
                  Another event may overlap this time at this site:{' '}
                  <strong>{scheduleConflictHint.title}</strong> (
                  {formatEventAdminDateTime(scheduleConflictHint.scheduledAt)}).{' '}
                  <Link href={`/dashboard/events/${scheduleConflictHint.id}`}>Open event</Link>.
                </>
              )}
            </div>
          ) : null}
          <label className={styles.field} htmlFor="detail-event-participants">
            <span className={styles.fieldLabel}>Participant count</span>
            <Input
              id="detail-event-participants"
              type="number"
              min={0}
              value={String(participantCount)}
              disabled={readOnly}
              onChange={(e) => {
                setParticipantCount(Math.max(0, parseInt(e.target.value, 10) || 0));
                clearFieldError('participantCount');
              }}
              className={styles.inputNumber}
              aria-invalid={fieldErrors.participantCount ? true : undefined}
              aria-describedby={fieldErrors.participantCount ? 'detail-event-participants-err' : undefined}
            />
            {fieldErrors.participantCount ? (
              <span id="detail-event-participants-err" className={styles.fieldError} role="alert">
                {fieldErrors.participantCount}
              </span>
            ) : null}
          </label>
          {!isCompleted && (
            <label className={styles.field}>
              <span className={styles.fieldLabel}>Mark as completed</span>
              <Button
                variant="outline"
                size="sm"
                onClick={() => void markComplete()}
                isLoading={saving}
                disabled={readOnly}
              >
                <Icon name="check" size={14} />
                Mark completed
              </Button>
            </label>
          )}
          {isCompleted && (
            <label className={styles.field} htmlFor="detail-event-completed">
              <span className={styles.fieldLabel}>Completed date & time</span>
              <input
                id="detail-event-completed"
                type="datetime-local"
                value={completedAt ? toDatetimeLocalField(completedAt) : ''}
                disabled={readOnly}
                onChange={(e) => {
                  setCompletedAt(e.target.value ? new Date(e.target.value).toISOString() : '');
                  clearFieldError('completedAt');
                }}
                className={styles.input}
                aria-invalid={fieldErrors.completedAt ? true : undefined}
                aria-describedby={fieldErrors.completedAt ? 'detail-event-completed-err' : undefined}
              />
              <span className={styles.fieldHint}>You can adjust when the event was completed.</span>
              {fieldErrors.completedAt ? (
                <span id="detail-event-completed-err" className={styles.fieldError} role="alert">
                  {fieldErrors.completedAt}
                </span>
              ) : null}
            </label>
          )}
          <div className={styles.formActions}>
            <Button onClick={() => void saveUpdates()} isLoading={saving} disabled={readOnly}>
              Save changes
            </Button>
          </div>
        </div>
      </section>

      <Snack snack={snack} onClose={() => setSnack(null)} />

      {duplicateModal ? (
        <div
          className={styles.modalBackdrop}
          role="presentation"
          onClick={() => setDuplicateModal(null)}
        >
          <div
            ref={duplicateModalCardRef}
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
              {formatEventAdminDateTime(duplicateModal.scheduledAt)}. Adjust the
              time or open the existing event.
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

      {declineModalOpen ? (
        <div
          className={styles.modalBackdrop}
          role="presentation"
          onClick={(e) => {
            if (e.target !== e.currentTarget || saving) {
              return;
            }
            setDeclineModalOpen(false);
            setDeclineReason('');
            setDeclineReasonError(null);
          }}
        >
          <div
            ref={declineModalCardRef}
            className={styles.modalCard}
            role="dialog"
            aria-modal="true"
            aria-labelledby="decline-event-modal-title"
            aria-describedby="decline-event-modal-desc"
            onClick={(ev) => ev.stopPropagation()}
          >
            <h2 id="decline-event-modal-title" className={styles.modalTitle}>
              Decline event
            </h2>
            <p id="decline-event-modal-desc" className={styles.modalBody}>
              Provide a short reason for declining. This is stored for audit purposes (3–2000 characters).
            </p>
            <label className={styles.field} htmlFor="decline-reason-text">
              <span className={styles.fieldLabel}>Reason</span>
              <textarea
                id="decline-reason-text"
                ref={declineReasonTextareaRef}
                value={declineReason}
                onChange={(e) => {
                  setDeclineReason(e.target.value);
                  setDeclineReasonError(null);
                }}
                className={styles.textarea}
                rows={4}
                maxLength={2000}
                disabled={saving}
                aria-invalid={declineReasonError ? true : undefined}
                aria-describedby={
                  declineReasonError
                    ? 'decline-event-modal-desc decline-reason-err'
                    : 'decline-event-modal-desc'
                }
              />
              {declineReasonError ? (
                <span id="decline-reason-err" className={styles.fieldError} role="alert">
                  {declineReasonError}
                </span>
              ) : null}
            </label>
            <div className={styles.modalActions}>
              <Button
                type="button"
                variant="outline"
                disabled={saving}
                onClick={() => {
                  setDeclineModalOpen(false);
                  setDeclineReason('');
                  setDeclineReasonError(null);
                }}
              >
                Cancel
              </Button>
              <Button type="button" isLoading={saving} onClick={() => void submitDecline()}>
                Decline event
              </Button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
