'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { Button, Icon, Input, Snack, type SnackState } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/admin-browser-api';
import { ApiError } from '@/lib/api';
import type { CleanupEventDetail } from '@/features/events/data/events-adapter';
import styles from './event-detail.module.css';

function formatDateTime(iso: string): string {
  return new Date(iso).toLocaleString(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  });
}

function toDatetimeLocal(iso: string): string {
  const d = new Date(iso);
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

type EventDetailViewProps = {
  event: CleanupEventDetail;
};

export function EventDetailView({ event }: EventDetailViewProps) {
  const router = useRouter();
  const [scheduledAt, setScheduledAt] = useState(event.scheduledAt);
  const [completedAt, setCompletedAt] = useState(event.completedAt ?? '');
  const [participantCount, setParticipantCount] = useState(event.participantCount);
  const [saving, setSaving] = useState(false);
  const [snack, setSnack] = useState<SnackState | null>(null);

  const isCompleted = !!event.completedAt;
  const moderationStatus = (event as { status?: string }).status ?? 'APPROVED';
  const isPending = moderationStatus === 'PENDING';
  const site = event.site;

  const gm = `https://www.google.com/maps?q=${site.latitude},${site.longitude}`;
  const am = `https://maps.apple.com/?q=${site.latitude},${site.longitude}`;

  async function saveUpdates() {
    setSaving(true);
    setSnack(null);
    const body: { scheduledAt: string; participantCount: number; completedAt?: string | null } = {
      scheduledAt: new Date(scheduledAt).toISOString(),
      participantCount,
    };
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
      const msg = e instanceof ApiError ? e.message : 'Update failed';
      setSnack({ tone: 'warning', title: 'Error', message: msg });
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
      const msg = e instanceof ApiError ? e.message : 'Approve failed';
      setSnack({ tone: 'warning', title: 'Error', message: msg });
    } finally {
      setSaving(false);
    }
  }

  async function decline() {
    setSaving(true);
    setSnack(null);
    try {
      await adminBrowserFetch(`/admin/cleanup-events/${event.id}`, {
        method: 'PATCH',
        body: { status: 'DECLINED' },
      });
      setSnack({ tone: 'success', title: 'Event declined', message: 'The event has been declined.' });
      router.refresh();
    } catch (e) {
      const msg = e instanceof ApiError ? e.message : 'Decline failed';
      setSnack({ tone: 'warning', title: 'Error', message: msg });
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
      const msg = e instanceof ApiError ? e.message : 'Update failed';
      setSnack({ tone: 'warning', title: 'Error', message: msg });
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
        <span className={styles.sectionLabel}>Event status</span>
        <div className={styles.statusRow}>
          <span className={isCompleted ? styles.statusCompleted : styles.statusUpcoming}>
            {isCompleted ? 'Completed' : 'Upcoming'}
          </span>
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
        <div className={styles.metaRow}>
          <div className={styles.metaItem}>
            <span className={styles.metaLabel}>Scheduled</span>
            <span className={styles.metaValue}>{formatDateTime(event.scheduledAt)}</span>
          </div>
          {event.completedAt && (
            <div className={styles.metaItem}>
              <span className={styles.metaLabel}>Completed</span>
              <span className={styles.metaValue}>{formatDateTime(event.completedAt)}</span>
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
        {isPending && (
          <div className={styles.approveDeclineBar}>
            <p className={styles.approveDeclineHint}>
              This event was created by a user and awaits your review. Approve to make it visible to participants, or decline to reject it.
            </p>
            <div className={styles.approveDeclineActions}>
              <Button onClick={() => void approve()} disabled={saving}>
                <Icon name="check" size={14} />
                Approve
              </Button>
              <Button variant="outline" onClick={() => void decline()} disabled={saving} className={styles.declineBtn}>
                Decline
              </Button>
            </div>
          </div>
        )}
        <p className={styles.moderationHint}>
          {isPending ? 'You can also edit details before approving.' : 'Edit event details. Changes are saved when you click Save.'}
        </p>
        <div className={styles.form}>
          <label className={styles.field}>
            <span className={styles.fieldLabel}>Scheduled date & time</span>
            <input
              type="datetime-local"
              value={toDatetimeLocal(scheduledAt)}
              onChange={(e) => setScheduledAt(new Date(e.target.value).toISOString())}
              className={styles.input}
            />
          </label>
          <label className={styles.field}>
            <span className={styles.fieldLabel}>Participant count</span>
            <Input
              type="number"
              min={0}
              value={String(participantCount)}
              onChange={(e) => setParticipantCount(Math.max(0, parseInt(e.target.value, 10) || 0))}
              className={styles.inputNumber}
            />
          </label>
          {!isCompleted && (
            <label className={styles.field}>
              <span className={styles.fieldLabel}>Mark as completed</span>
              <Button
                variant="outline"
                size="sm"
                onClick={() => void markComplete()}
                disabled={saving}
              >
                <Icon name="check" size={14} />
                Mark completed
              </Button>
            </label>
          )}
          {isCompleted && (
            <label className={styles.field}>
              <span className={styles.fieldLabel}>Completed date & time</span>
              <input
                type="datetime-local"
                value={completedAt ? toDatetimeLocal(completedAt) : ''}
                onChange={(e) => setCompletedAt(e.target.value ? new Date(e.target.value).toISOString() : '')}
                className={styles.input}
              />
              <span className={styles.fieldHint}>You can adjust when the event was completed.</span>
            </label>
          )}
          <div className={styles.formActions}>
            <Button onClick={() => void saveUpdates()} disabled={saving}>
              {saving ? 'Saving…' : 'Save changes'}
            </Button>
          </div>
        </div>
      </section>

      <Snack snack={snack} onClose={() => setSnack(null)} />
    </div>
  );
}
