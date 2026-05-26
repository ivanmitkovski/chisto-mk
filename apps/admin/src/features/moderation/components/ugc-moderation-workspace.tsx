'use client';

import { useMemo, useState } from 'react';
import { Badge, Button, Card, Modal, SectionState, Snack, type SnackState } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/admin-browser-api';
import type { UgcModerationReport } from '../data/ugc-moderation-adapter';
import styles from './ugc-moderation-workspace.module.css';

type ModerationAction = 'mark_reviewed' | 'dismiss' | 'escalate' | 'hide_subject' | 'restore_subject';

const actions: Array<{ id: ModerationAction; label: string; tone: 'neutral' | 'success' | 'warning' | 'danger' }> = [
  { id: 'mark_reviewed', label: 'Mark reviewed', tone: 'success' },
  { id: 'dismiss', label: 'Dismiss', tone: 'neutral' },
  { id: 'escalate', label: 'Escalate', tone: 'warning' },
  { id: 'hide_subject', label: 'Hide subject', tone: 'danger' },
  { id: 'restore_subject', label: 'Restore subject', tone: 'success' },
];

function badgeTone(status: string): 'neutral' | 'success' | 'warning' | 'danger' | 'info' {
  if (status === 'OPEN') return 'warning';
  if (status === 'ESCALATED') return 'danger';
  if (status === 'HIDDEN') return 'info';
  if (status === 'REVIEWED') return 'success';
  return 'neutral';
}

function formatLabel(value: string): string {
  return value.replace(/_/g, ' ').replace(/\b\w/g, (char) => char.toUpperCase());
}

export function UgcModerationWorkspace({ initialReports }: { initialReports: UgcModerationReport[] }) {
  const [reports, setReports] = useState(initialReports);
  const [selectedReport, setSelectedReport] = useState<UgcModerationReport | null>(initialReports[0] ?? null);
  const [pendingAction, setPendingAction] = useState<ModerationAction | null>(null);
  const [note, setNote] = useState('');
  const [busy, setBusy] = useState(false);
  const [snack, setSnack] = useState<SnackState | null>(null);

  const openCount = useMemo(() => reports.filter((report) => report.status === 'OPEN').length, [reports]);

  async function submitAction() {
    if (!selectedReport || !pendingAction) return;
    setBusy(true);
    try {
      const updated = await adminBrowserFetch<UgcModerationReport>(
        `/admin/moderation/ugc-reports/${encodeURIComponent(selectedReport.id)}`,
        {
          method: 'PATCH',
          body: { action: pendingAction, note: note.trim() || undefined },
        },
      );
      setReports((current) => current.map((report) => (report.id === updated.id ? updated : report)));
      setSelectedReport(updated);
      setPendingAction(null);
      setNote('');
      setSnack({ tone: 'success', title: 'Moderation saved', message: 'The UGC report was updated.' });
    } catch (error) {
      setSnack({
        tone: 'warning',
        title: 'Moderation failed',
        message: error instanceof Error ? error.message : 'Unable to update this UGC report.',
      });
    } finally {
      setBusy(false);
    }
  }

  if (reports.length === 0) {
    return <SectionState variant="empty" message="No UGC reports are waiting for review." />;
  }

  return (
    <div className={styles.layout}>
      <aside className={styles.queue} aria-label="UGC report queue">
        <div className={styles.queueHeader}>
          <div>
            <strong>{reports.length} reports</strong>
            <span>{openCount} open</span>
          </div>
        </div>
        {reports.map((report) => (
          <button
            key={report.id}
            type="button"
            className={report.id === selectedReport?.id ? `${styles.queueItem} ${styles.queueItemActive}` : styles.queueItem}
            onClick={() => setSelectedReport(report)}
          >
            <span>{formatLabel(report.subjectType)}</span>
            <Badge tone={badgeTone(report.status)}>{report.status}</Badge>
            <small>{report.reason}</small>
          </button>
        ))}
      </aside>

      {selectedReport ? (
        <Card padding="md" className={styles.detail}>
          <div className={styles.detailHeader}>
            <div>
              <p className={styles.kicker}>UGC report</p>
              <h2>{formatLabel(selectedReport.subjectType)}</h2>
            </div>
            <Badge tone={badgeTone(selectedReport.status)}>{selectedReport.status}</Badge>
          </div>

          <dl className={styles.metaGrid}>
            <div>
              <dt>Subject</dt>
              <dd>{selectedReport.subjectId}</dd>
            </div>
            <div>
              <dt>Reason</dt>
              <dd>{formatLabel(selectedReport.reason)}</dd>
            </div>
            <div>
              <dt>Reporter</dt>
              <dd>
                {selectedReport.reporterName || 'Unknown'}
                {selectedReport.reporterEmail ? <span>{selectedReport.reporterEmail}</span> : null}
              </dd>
            </div>
            <div>
              <dt>Created</dt>
              <dd>{new Date(selectedReport.createdAt).toLocaleString()}</dd>
            </div>
          </dl>

          {selectedReport.details ? (
            <section className={styles.detailsBox}>
              <h3>Reporter details</h3>
              <p>{selectedReport.details}</p>
            </section>
          ) : null}

          <div className={styles.actions}>
            {actions.map((action) => (
              <Button
                key={action.id}
                type="button"
                variant={action.tone === 'neutral' ? 'outline' : 'solid'}
                onClick={() => setPendingAction(action.id)}
              >
                {action.label}
              </Button>
            ))}
          </div>
        </Card>
      ) : null}

      <Modal
        open={pendingAction != null}
        title={pendingAction ? actions.find((action) => action.id === pendingAction)?.label ?? 'Moderate report' : 'Moderate report'}
        description="This action will be audited and visible to other admins."
        onClose={() => setPendingAction(null)}
        footer={
          <>
            <Button type="button" variant="outline" onClick={() => setPendingAction(null)} disabled={busy}>
              Cancel
            </Button>
            <Button type="button" onClick={() => void submitAction()} isLoading={busy}>
              Confirm
            </Button>
          </>
        }
      >
        <label className={styles.noteField}>
          <span>Moderator note</span>
          <textarea value={note} onChange={(event) => setNote(event.target.value)} maxLength={1000} />
        </label>
      </Modal>
      <Snack snack={snack} onClose={() => setSnack(null)} />
    </div>
  );
}
