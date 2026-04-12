'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { Button, Icon, Snack, type SnackState } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/admin-browser-api';
import { ApiError } from '@/lib/api';
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

  const [title, setTitle] = useState('Cleanup event');
  const [description, setDescription] = useState('');
  const [recurrenceRule, setRecurrenceRule] = useState('');
  const [scheduledAt, setScheduledAt] = useState(toDatetimeLocal(defaultDate));
  const [participantCount, setParticipantCount] = useState(0);
  const [createAsPending, setCreateAsPending] = useState(false);
  const [saving, setSaving] = useState(false);
  const [snack, setSnack] = useState<SnackState | null>(null);

  async function submit() {
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
      const msg = e instanceof ApiError ? e.message : 'Create failed';
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
        <span className={styles.sectionLabel}>New cleanup event</span>
        <p className={styles.hint}>
          Create a cleanup event for site <code className={styles.siteId}>{siteId}</code>.
          <Link href={`/dashboard/sites/${siteId}`} className={styles.siteLink}>
            View site
          </Link>
        </p>
        <div className={styles.form}>
          <label className={styles.field}>
            <span className={styles.fieldLabel}>Title</span>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className={styles.input}
              maxLength={200}
            />
          </label>
          <label className={styles.field}>
            <span className={styles.fieldLabel}>Description</span>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className={styles.input}
              rows={4}
              maxLength={10000}
            />
          </label>
          <label className={styles.field}>
            <span className={styles.fieldLabel}>Recurrence (optional RFC 5545 RRULE)</span>
            <textarea
              value={recurrenceRule}
              onChange={(e) => setRecurrenceRule(e.target.value)}
              className={styles.input}
              rows={2}
              placeholder="FREQ=WEEKLY;BYDAY=SA;COUNT=8"
              maxLength={2048}
            />
            <span className={styles.fieldHint}>
              Stored on this event for reference; admin create does not expand a series in the database.
            </span>
          </label>
          <label className={styles.field}>
            <span className={styles.fieldLabel}>Scheduled date & time</span>
            <input
              type="datetime-local"
              value={scheduledAt}
              onChange={(e) => setScheduledAt(e.target.value)}
              className={styles.input}
            />
          </label>
          <label className={styles.fieldCheck}>
            <input
              type="checkbox"
              checked={createAsPending}
              onChange={(e) => setCreateAsPending(e.target.checked)}
            />
            <span>Create as pending (simulate user submission, requires approval)</span>
          </label>
          <label className={styles.field}>
            <span className={styles.fieldLabel}>Initial participant count</span>
            <input
              type="number"
              min={0}
              value={participantCount}
              onChange={(e) => setParticipantCount(Math.max(0, parseInt(e.target.value, 10) || 0))}
              className={styles.input}
            />
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
    </div>
  );
}
