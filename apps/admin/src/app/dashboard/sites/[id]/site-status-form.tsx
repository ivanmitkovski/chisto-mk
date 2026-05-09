'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { Button, Icon, Snack, type SnackState } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/admin-browser-api';
import { ApiError } from '@/lib/api';
import styles from './site-detail.module.css';

const ALLOWED_TRANSITIONS: Record<string, string[]> = {
  REPORTED: ['VERIFIED', 'DISPUTED'],
  VERIFIED: ['CLEANUP_SCHEDULED', 'DISPUTED'],
  CLEANUP_SCHEDULED: ['IN_PROGRESS', 'DISPUTED'],
  IN_PROGRESS: ['CLEANED', 'DISPUTED'],
  CLEANED: ['DISPUTED'],
  DISPUTED: ['REPORTED', 'VERIFIED'],
};

function formatStatus(s: string): string {
  return s.replace(/_/g, ' ').toLowerCase().replace(/\b\w/g, (c) => c.toUpperCase());
}

function statusPillClass(status: string): string {
  const map: Record<string, string> = {
    REPORTED: styles.statusReported,
    VERIFIED: styles.statusVerified,
    CLEANUP_SCHEDULED: styles.statusScheduled,
    IN_PROGRESS: styles.statusInProgress,
    CLEANED: styles.statusCleaned,
    DISPUTED: styles.statusDisputed,
  };
  return `${styles.statusPill} ${map[status] ?? ''}`;
}

type SiteStatusFormProps = {
  siteId: string;
  initialStatus: string;
  initialArchivedByAdmin: boolean;
  initialArchiveReason: string | null;
  latitude: number;
  longitude: number;
  description: string | null;
  reportCount: number;
  createdAt: string;
};

export function SiteStatusForm({
  siteId,
  initialStatus,
  initialArchivedByAdmin,
  initialArchiveReason,
  latitude,
  longitude,
  description,
  reportCount,
  createdAt,
}: SiteStatusFormProps) {
  const router = useRouter();
  const [currentStatus, setCurrentStatus] = useState(initialStatus);
  const [status, setStatus] = useState(initialStatus);
  const [isArchived, setIsArchived] = useState(initialArchivedByAdmin);
  const [archiveReason, setArchiveReason] = useState(initialArchiveReason ?? '');
  const [saving, setSaving] = useState(false);
  const [snack, setSnack] = useState<SnackState | null>(null);

  const allowedNext = ALLOWED_TRANSITIONS[currentStatus] ?? [];
  const canChange = allowedNext.length > 0;

  const gm = `https://www.google.com/maps?q=${latitude},${longitude}`;
  const am = `https://maps.apple.com/?q=${latitude},${longitude}`;

  const createdDate = new Date(createdAt).toLocaleDateString(undefined, {
    dateStyle: 'medium',
  });

  async function save() {
    setSaving(true);
    setSnack(null);
    try {
      await adminBrowserFetch(`/sites/${siteId}/status`, {
        method: 'PATCH',
        body: { status },
      });
      setCurrentStatus(status);
      setSnack({ tone: 'success', title: 'Saved', message: 'Site status updated.' });
      router.refresh();
    } catch (e) {
      const msg = e instanceof ApiError ? e.message : 'Update failed';
      setSnack({ tone: 'warning', title: 'Error', message: msg });
    } finally {
      setSaving(false);
    }
  }

  async function saveArchive() {
    if (isArchived && !archiveReason.trim()) {
      setSnack({ tone: 'warning', title: 'Reason required', message: 'Add archive reason before saving.' });
      return;
    }
    setSaving(true);
    setSnack(null);
    try {
      await adminBrowserFetch(`/sites/${siteId}/archive`, {
        method: 'PATCH',
        body: { archived: isArchived, reason: archiveReason.trim() || undefined },
      });
      setSnack({
        tone: 'success',
        title: 'Saved',
        message: isArchived ? 'Site archived from default map visibility.' : 'Site unarchived.',
      });
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
      <Link href="/dashboard/sites" className={styles.backLink}>
        <Icon name="chevron-left" size={16} />
        Back to sites
      </Link>

      <section className={styles.sectionCard}>
        <span className={styles.sectionLabel}>Location</span>
        <p className={styles.coordsValue}>
          {latitude.toFixed(6)}, {longitude.toFixed(6)}
        </p>
        {description ? <p className={styles.description}>{description}</p> : null}
        <div className={styles.mapLinks}>
          <a
            href={gm}
            target="_blank"
            rel="noopener noreferrer"
            className={styles.mapBtn}
          >
            Open in Google Maps
          </a>
          <a
            href={am}
            target="_blank"
            rel="noopener noreferrer"
            className={styles.mapBtn}
          >
            Open in Apple Maps
          </a>
        </div>
        <div className={styles.metaRow}>
          <Link
            href={`/dashboard/events/new?siteId=${siteId}`}
            className={styles.createEventLink}
          >
            <Icon name="calendar" size={14} />
            Create cleanup event
          </Link>
          <div className={styles.metaItem}>
            <span className={styles.metaLabel}>Reports</span>
            <span className={styles.metaValue}>
              {reportCount > 0 ? (
                <Link href={`/dashboard/reports?siteId=${siteId}`} className={styles.reportsLink}>
                  {reportCount}
                </Link>
              ) : (
                reportCount
              )}
            </span>
          </div>
          <div className={styles.metaItem}>
            <span className={styles.metaLabel}>Reported</span>
            <span className={styles.metaValue}>{createdDate}</span>
          </div>
        </div>
      </section>

      <section className={styles.sectionCard}>
        <span className={styles.sectionLabel}>Lifecycle status</span>
        <div className={styles.statusForm}>
          <span className={statusPillClass(currentStatus)}>
            {formatStatus(currentStatus)}
          </span>
          {canChange && (
            <>
              <label htmlFor="site-status">
                <span className={styles.metaLabel}>Change to</span>
                <select
                  id="site-status"
                  value={status}
                  onChange={(e) => setStatus(e.target.value)}
                >
                  {allowedNext.map((st) => (
                    <option key={st} value={st}>
                      {formatStatus(st)}
                    </option>
                  ))}
                </select>
              </label>
              <div className={styles.formActions}>
                <Button type="button" onClick={() => void save()} disabled={saving}>
                  {saving ? 'Saving…' : 'Save status'}
                </Button>
                {saving && <span className={styles.saving}>Updating…</span>}
              </div>
            </>
          )}
        </div>
      </section>

      <section className={styles.sectionCard}>
        <span className={styles.sectionLabel}>Visibility moderation</span>
        <div className={styles.statusForm}>
          <label>
            <span className={styles.metaLabel}>Map visibility</span>
            <select
              value={isArchived ? 'archived' : 'visible'}
              onChange={(e) => setIsArchived(e.target.value === 'archived')}
            >
              <option value="visible">Visible by default</option>
              <option value="archived">Archived (hidden by default)</option>
            </select>
          </label>
          <label>
            <span className={styles.metaLabel}>Moderation reason</span>
            <textarea
              value={archiveReason}
              onChange={(e) => setArchiveReason(e.target.value)}
              placeholder="Why should this site be archived?"
              rows={3}
            />
          </label>
          <div className={styles.formActions}>
            <Button type="button" onClick={() => void saveArchive()} disabled={saving}>
              {saving ? 'Saving…' : 'Save visibility'}
            </Button>
          </div>
        </div>
      </section>

      <Snack snack={snack} onClose={() => setSnack(null)} />
    </div>
  );
}
