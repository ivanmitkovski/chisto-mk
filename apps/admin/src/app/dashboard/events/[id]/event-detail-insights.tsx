'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui';
import { useFocusTrap } from '@/lib/use-focus-trap';
import type {
  AuditLogAdminRow,
  CleanupEventParticipantAdminRow,
  EventAnalyticsAdminPayload,
} from '@/features/events/data/events-adapter';
import {
  fetchCleanupEventAnalyticsClient,
  fetchCleanupEventAuditClient,
  fetchCleanupEventParticipantsClient,
} from '@/features/events/data/events-adapter-client';
import { adminBrowserFetch } from '@/lib/admin-browser-api';
import { cleanupEventMutationMessage } from '@/features/events/lib/cleanup-events-api-messages';
import styles from './event-detail.module.css';

type InsightTab = 'analytics' | 'audit' | 'participants' | 'lifecycle';

function formatAuditMetadata(meta: unknown): string {
  if (meta == null) {
    return '—';
  }
  try {
    const s = JSON.stringify(meta);
    return s.length > 200 ? `${s.slice(0, 200)}…` : s;
  } catch {
    return String(meta);
  }
}

export function EventDetailInsights(props: {
  eventId: string;
  lifecycleStatus: string;
  canWrite: boolean;
}) {
  const router = useRouter();
  const [tab, setTab] = useState<InsightTab | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [analytics, setAnalytics] = useState<EventAnalyticsAdminPayload | null>(null);
  const [audit, setAudit] = useState<{ data: AuditLogAdminRow[]; meta: { total: number } } | null>(null);
  const [participants, setParticipants] = useState<CleanupEventParticipantAdminRow[] | null>(null);
  const [lifecycleBusy, setLifecycleBusy] = useState(false);
  const [cancelOpen, setCancelOpen] = useState(false);
  const cancelCardRef = useRef<HTMLDivElement>(null);
  const cancelPrimaryRef = useRef<HTMLButtonElement>(null);

  useFocusTrap(cancelOpen, cancelCardRef);

  useEffect(() => {
    if (!cancelOpen) {
      return;
    }
    cancelPrimaryRef.current?.focus();
  }, [cancelOpen]);

  useEffect(() => {
    if (!cancelOpen) {
      return;
    }
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        if (!lifecycleBusy) {
          setCancelOpen(false);
        }
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [cancelOpen, lifecycleBusy]);

  const loadTab = useCallback(async (next: InsightTab) => {
    setTab(next);
    setError(null);
    setLoading(true);
    try {
      if (next === 'analytics') {
        setAnalytics(await fetchCleanupEventAnalyticsClient(props.eventId));
      } else if (next === 'audit') {
        setAudit(await fetchCleanupEventAuditClient(props.eventId, 1, 50));
      } else if (next === 'participants') {
        const r = await fetchCleanupEventParticipantsClient(props.eventId);
        setParticipants(r.data);
      }
    } catch (e) {
      setError(cleanupEventMutationMessage(e, 'Could not load data'));
    } finally {
      setLoading(false);
    }
  }, [props.eventId]);

  async function confirmCancelEvent() {
    if (!props.canWrite) {
      return;
    }
    setLifecycleBusy(true);
    setError(null);
    try {
      await adminBrowserFetch(`/admin/cleanup-events/${props.eventId}`, {
        method: 'PATCH',
        body: { lifecycleStatus: 'CANCELLED' },
      });
      setCancelOpen(false);
      router.refresh();
    } catch (e) {
      setError(cleanupEventMutationMessage(e, 'Could not cancel event'));
    } finally {
      setLifecycleBusy(false);
    }
  }

  const showCancel =
    props.canWrite &&
    props.lifecycleStatus !== 'CANCELLED' &&
    props.lifecycleStatus !== 'COMPLETED';

  return (
    <section className={styles.sectionCard} aria-label="Event insights">
      <span className={styles.sectionLabel}>Insights</span>
      <div className={styles.metaRow} style={{ flexWrap: 'wrap', gap: 8 }}>
        <Button type="button" variant="outline" size="sm" onClick={() => void loadTab('analytics')}>
          Analytics
        </Button>
        <Button type="button" variant="outline" size="sm" onClick={() => void loadTab('audit')}>
          Audit log
        </Button>
        <Button type="button" variant="outline" size="sm" onClick={() => void loadTab('participants')}>
          Participants
        </Button>
        <Button type="button" variant="outline" size="sm" onClick={() => setTab('lifecycle')}>
          Lifecycle
        </Button>
        {tab != null ? (
          <Button type="button" variant="ghost" size="sm" onClick={() => setTab(null)}>
            Close panel
          </Button>
        ) : null}
      </div>
      {error ? (
        <p className={styles.fieldError} role="alert">
          {error}
        </p>
      ) : null}
      {loading ? (
        <p className={styles.fieldHint} role="status" aria-live="polite" aria-label="Loading">
          Loading…
        </p>
      ) : null}
      {tab === 'analytics' && analytics != null ? (
        <div className={styles.insightPanel}>
          <p className={styles.fieldHint}>
            Joiners (headline): {analytics.totalJoiners} · Checked in: {analytics.checkedInCount} · Attendance:{' '}
            {analytics.attendanceRate}%
          </p>
          <p className={styles.fieldHint}>
            Cumulative join series may be truncated for very large events; hourly check-ins use UTC buckets.
          </p>
          <h3 className={styles.insightSubheading}>Cumulative joiners</h3>
          <div className={styles.insightTableWrap}>
            <table className={styles.insightTable}>
              <thead>
                <tr>
                  <th scope="col">Time (UTC)</th>
                  <th scope="col">Cumulative</th>
                </tr>
              </thead>
              <tbody>
                {analytics.joinersCumulative.length === 0 ? (
                  <tr>
                    <td colSpan={2}>
                      No data available
                    </td>
                  </tr>
                ) : (
                  analytics.joinersCumulative.map((row) => (
                    <tr key={row.at}>
                      <td>{new Date(row.at).toISOString()}</td>
                      <td>{row.cumulativeJoiners}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
          <h3 className={styles.insightSubheading}>Check-ins by hour (UTC)</h3>
          <div className={styles.insightTableWrap}>
            <table className={styles.insightTable}>
              <thead>
                <tr>
                  <th scope="col">Hour</th>
                  <th scope="col">Count</th>
                </tr>
              </thead>
              <tbody>
                {(() => {
                  const rows = analytics.checkInsByHour.filter((h) => h.count > 0);
                  return rows.length === 0 ? (
                    <tr>
                      <td colSpan={2}>
                        No data available
                      </td>
                    </tr>
                  ) : (
                    rows.map((h) => (
                      <tr key={h.hour}>
                        <td>{h.hour}</td>
                        <td>{h.count}</td>
                      </tr>
                    ))
                  );
                })()}
              </tbody>
            </table>
          </div>
        </div>
      ) : null}
      {tab === 'audit' && audit != null ? (
        <div className={styles.insightPanel}>
          <p className={styles.fieldHint}>{audit.meta.total} audit entries (first page)</p>
          <div className={styles.insightTableWrap}>
            <table className={styles.insightTable}>
              <thead>
                <tr>
                  <th scope="col">When</th>
                  <th scope="col">Action</th>
                  <th scope="col">Actor</th>
                  <th scope="col">Resource</th>
                  <th scope="col">Metadata</th>
                </tr>
              </thead>
              <tbody>
                {audit.data.length === 0 ? (
                  <tr>
                    <td colSpan={5}>
                      No data available
                    </td>
                  </tr>
                ) : (
                  audit.data.map((row) => (
                    <tr key={row.id}>
                      <td>{new Date(row.createdAt).toLocaleString()}</td>
                      <td>{row.action}</td>
                      <td>{row.actorEmail ?? '—'}</td>
                      <td>
                        {row.resourceType}
                        {row.resourceId ? ` · ${row.resourceId}` : ''}
                      </td>
                      <td title={formatAuditMetadata(row.metadata)}>{formatAuditMetadata(row.metadata)}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      ) : null}
      {tab === 'participants' && participants != null ? (
        <div className={styles.insightPanel}>
          <table className={styles.insightTable}>
            <thead>
              <tr>
                <th scope="col">Name</th>
                <th scope="col">Email</th>
                <th scope="col">Joined</th>
              </tr>
            </thead>
            <tbody>
              {participants.length === 0 ? (
                <tr>
                  <td colSpan={3}>
                    No data available
                  </td>
                </tr>
              ) : (
                participants.map((p) => (
                  <tr key={p.userId}>
                    <td>{p.displayName}</td>
                    <td>{p.email}</td>
                    <td>{new Date(p.joinedAt).toLocaleString()}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      ) : null}
      {tab === 'lifecycle' ? (
        <div className={styles.insightPanel}>
          <p className={styles.fieldHint}>Current lifecycle: {props.lifecycleStatus}</p>
          {showCancel ? (
            <Button type="button" variant="outline" disabled={lifecycleBusy} onClick={() => setCancelOpen(true)}>
              Cancel event…
            </Button>
          ) : (
            <p className={styles.fieldHint}>No lifecycle actions available.</p>
          )}
        </div>
      ) : null}

      {cancelOpen ? (
        <div
          className={styles.modalBackdrop}
          role="presentation"
          onClick={(e) => {
            if (e.target === e.currentTarget && !lifecycleBusy) {
              setCancelOpen(false);
            }
          }}
        >
          <div
            ref={cancelCardRef}
            className={styles.modalCard}
            role="dialog"
            aria-modal="true"
            aria-labelledby="cancel-event-title"
            aria-describedby="cancel-event-desc"
          >
            <h2 id="cancel-event-title" className={styles.modalTitle}>
              Cancel this event?
            </h2>
            <p id="cancel-event-desc" className={styles.modalBody}>
              Participants will see this cleanup as cancelled. This action is visible in the audit log.
            </p>
            <div className={styles.modalActions}>
              <Button
                type="button"
                variant="ghost"
                onClick={() => setCancelOpen(false)}
                disabled={lifecycleBusy}
              >
                Keep event
              </Button>
              <Button
                ref={cancelPrimaryRef}
                type="button"
                variant="outline"
                isLoading={lifecycleBusy}
                onClick={() => void confirmCancelEvent()}
              >
                Confirm cancel
              </Button>
            </div>
          </div>
        </div>
      ) : null}
    </section>
  );
}
