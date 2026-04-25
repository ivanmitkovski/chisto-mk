'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import dynamic from 'next/dynamic';
import { useCallback, useEffect, useRef, useState } from 'react';
import { Button, Card, Pagination, Snack, type SnackState } from '@/components/ui';
import { useFocusTrap } from '@/lib/use-focus-trap';
import type { CleanupEventRow, EventsStats } from '@/features/events/data/events-adapter';
import { adminBrowserFetch } from '@/lib/admin-browser-api';
import styles from './events-workspace.module.css';

const EventsWorkspaceStatsMotion = dynamic(
  () =>
    import('./events-workspace-stats-motion').then((m) => ({
      default: m.EventsWorkspaceStatsMotion,
    })),
  { ssr: false, loading: () => <div className={styles.statsBar} aria-hidden /> },
);

const STATUS_OPTIONS = [
  { value: '', label: 'All events' },
  { value: 'upcoming', label: 'Upcoming' },
  { value: 'completed', label: 'Completed' },
];

const MODERATION_OPTIONS = [
  { value: '', label: 'All statuses' },
  { value: 'PENDING', label: 'Pending' },
  { value: 'APPROVED', label: 'Approved' },
  { value: 'DECLINED', label: 'Declined' },
];

function formatDateTime(iso: string): string {
  const d = new Date(iso);
  return d.toLocaleString(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  });
}

function mapLinks(lat: number, lng: number) {
  return {
    gm: `https://www.google.com/maps?q=${lat},${lng}`,
    am: `https://maps.apple.com/?q=${lat},${lng}`,
  };
}

type EventsWorkspaceProps = {
  initialData: CleanupEventRow[];
  initialMeta: { total: number; page: number; limit: number };
  initialStats: EventsStats;
  /** True when the signed-in user may POST/PATCH cleanup events (ADMIN / SUPER_ADMIN). */
  canWriteCleanupEvents: boolean;
};

export function EventsWorkspace({
  initialData,
  initialMeta,
  initialStats,
  canWriteCleanupEvents,
}: EventsWorkspaceProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [data, setData] = useState(initialData);
  const [meta, setMeta] = useState(initialMeta);
  const [stats, setStats] = useState(initialStats);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(() => new Set());
  const [bulkBusy, setBulkBusy] = useState(false);
  const [snack, setSnack] = useState<SnackState | null>(null);
  const [bulkDeclineOpen, setBulkDeclineOpen] = useState(false);
  const [bulkDeclineReason, setBulkDeclineReason] = useState('');
  const [bulkDeclineError, setBulkDeclineError] = useState<string | null>(null);
  const bulkDeclineCardRef = useRef<HTMLDivElement>(null);
  const bulkDeclineReasonRef = useRef<HTMLTextAreaElement>(null);

  useFocusTrap(bulkDeclineOpen, bulkDeclineCardRef);

  useEffect(() => {
    if (!bulkDeclineOpen) {
      return;
    }
    const id = requestAnimationFrame(() => {
      bulkDeclineReasonRef.current?.focus();
    });
    return () => cancelAnimationFrame(id);
  }, [bulkDeclineOpen]);

  useEffect(() => {
    if (!bulkDeclineOpen) {
      return;
    }
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        if (!bulkBusy) {
          setBulkDeclineOpen(false);
          setBulkDeclineReason('');
          setBulkDeclineError(null);
        }
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [bulkDeclineOpen, bulkBusy]);

  const status = searchParams.get('status') ?? '';
  const moderationStatus = searchParams.get('moderationStatus') ?? '';

  useEffect(() => {
    setData(initialData);
    setMeta(initialMeta);
  }, [initialData, initialMeta]);

  useEffect(() => {
    setSelectedIds(new Set());
  }, [initialData, moderationStatus]);

  useEffect(() => {
    setStats(initialStats);
  }, [initialStats]);

  const buildUrl = (updates: { status?: string; moderationStatus?: string; page?: number }) => {
    const sp = new URLSearchParams(searchParams.toString());
    if (updates.status !== undefined) {
      if (updates.status) sp.set('status', updates.status);
      else sp.delete('status');
    }
    if (updates.moderationStatus !== undefined) {
      if (updates.moderationStatus) sp.set('moderationStatus', updates.moderationStatus);
      else sp.delete('moderationStatus');
    }
    if (updates.page !== undefined) {
      if (updates.page > 1) sp.set('page', String(updates.page));
      else sp.delete('page');
    }
    const q = sp.toString();
    return `/dashboard/events${q ? `?${q}` : ''}`;
  };

  const handleStatusChange = (value: string) => {
    router.push(buildUrl({ status: value, page: 1 }));
  };

  const handleModerationChange = (value: string) => {
    router.push(buildUrl({ moderationStatus: value, page: 1 }));
  };

  const refresh = () => router.refresh();

  const totalParticipants = data.reduce((sum, e) => sum + e.participantCount, 0);

  const toggleRowSelected = useCallback((id: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  }, []);

  const selectAllOnPage = useCallback(() => {
    setSelectedIds(new Set(data.map((e) => e.id)));
  }, [data]);

  const clearSelection = useCallback(() => {
    setSelectedIds(new Set());
  }, []);

  const bulkApprove = useCallback(async () => {
    if (!canWriteCleanupEvents || selectedIds.size === 0) {
      return;
    }
    setBulkBusy(true);
    setSnack(null);
    try {
      const clientJobId = crypto.randomUUID();
      await adminBrowserFetch<{ processed: number; failed: unknown[] }>('/admin/cleanup-events/bulk-moderate', {
        method: 'POST',
        body: {
          eventIds: [...selectedIds],
          action: 'APPROVED',
          clientJobId,
        },
      });
      setSelectedIds(new Set());
      refresh();
    } catch {
      setSnack({
        tone: 'warning',
        title: 'Bulk approve failed',
        message: 'Try again or approve events individually.',
      });
    } finally {
      setBulkBusy(false);
    }
  }, [canWriteCleanupEvents, refresh, selectedIds]);

  const openBulkDeclineModal = useCallback(() => {
    if (!canWriteCleanupEvents || selectedIds.size === 0) {
      return;
    }
    setBulkDeclineReason('');
    setBulkDeclineError(null);
    setBulkDeclineOpen(true);
  }, [canWriteCleanupEvents, selectedIds]);

  const submitBulkDecline = useCallback(async () => {
    const reason = bulkDeclineReason.trim();
    if (reason.length < 3) {
      setBulkDeclineError('Use at least 3 characters.');
      return;
    }
    setBulkBusy(true);
    setSnack(null);
    try {
      const clientJobId = crypto.randomUUID();
      await adminBrowserFetch<{ processed: number; failed: unknown[] }>('/admin/cleanup-events/bulk-moderate', {
        method: 'POST',
        body: {
          eventIds: [...selectedIds],
          action: 'DECLINED',
          declineReason: reason,
          clientJobId,
        },
      });
      setBulkDeclineOpen(false);
      setBulkDeclineReason('');
      setSelectedIds(new Set());
      refresh();
    } catch {
      setSnack({
        tone: 'warning',
        title: 'Bulk decline failed',
        message: 'Try again or decline events individually.',
      });
    } finally {
      setBulkBusy(false);
    }
  }, [bulkDeclineReason, refresh, selectedIds]);

  const showModerationBulk = moderationStatus === 'PENDING' && canWriteCleanupEvents;

  return (
    <div className={styles.layout}>
      <EventsWorkspaceStatsMotion
        stats={stats}
        totalParticipants={totalParticipants}
        moderationQueueHref={buildUrl({ moderationStatus: 'PENDING', page: 1 })}
      />

      <Card className={styles.tableCard}>
        <div className={styles.toolbar}>
          <div className={styles.filters}>
            <div className={styles.createHintBlock}>
              <div className={styles.createHintRow}>
                <Link href="/dashboard/sites" className={styles.createHint}>
                  Create event from site
                </Link>
                <span className={styles.hintDivider} aria-hidden>
                  ·
                </span>
                <Link href="/dashboard/events/risk-signals" className={styles.createHint}>
                  Check-in risk signals
                </Link>
              </div>
              {!canWriteCleanupEvents ? (
                <p className={styles.readOnlyHint} role="note">
                  Your role can view events; only admins can create or edit cleanup events.
                </p>
              ) : null}
            </div>
            <select
              value={status}
              onChange={(e) => handleStatusChange(e.target.value)}
              className={styles.filterSelect}
              aria-label="Filter by completion"
            >
              {STATUS_OPTIONS.map((o) => (
                <option key={o.value || '_'} value={o.value}>
                  {o.label}
                </option>
              ))}
            </select>
            <select
              value={moderationStatus}
              onChange={(e) => handleModerationChange(e.target.value)}
              className={styles.filterSelect}
              aria-label="Filter by moderation status"
            >
              {MODERATION_OPTIONS.map((o) => (
                <option key={o.value || '_'} value={o.value}>
                  {o.label}
                </option>
              ))}
            </select>
          </div>
          <Button variant="outline" size="sm" onClick={refresh}>
            Refresh
          </Button>
        </div>

        {showModerationBulk ? (
          <div className={styles.moderationBulkBar}>
            <span className={styles.moderationBulkMeta}>
              {selectedIds.size} selected · SSE refreshes this list automatically
            </span>
            <div className={styles.moderationBulkActions}>
              <Button variant="outline" size="sm" type="button" onClick={selectAllOnPage} disabled={bulkBusy}>
                Select page
              </Button>
              <Button variant="outline" size="sm" type="button" onClick={clearSelection} disabled={bulkBusy}>
                Clear
              </Button>
              <Button
                variant="solid"
                size="sm"
                type="button"
                onClick={() => void bulkApprove()}
                isLoading={bulkBusy}
                disabled={selectedIds.size === 0}
              >
                Approve selected
              </Button>
              <Button
                variant="outline"
                size="sm"
                type="button"
                onClick={openBulkDeclineModal}
                disabled={bulkBusy || selectedIds.size === 0}
              >
                Decline selected
              </Button>
            </div>
          </div>
        ) : null}

        <div className={styles.tableWrap}>
          {data.length === 0 ? (
            <div className={styles.empty}>No events match your filters.</div>
          ) : (
            <table className={styles.table}>
              <thead>
                <tr>
                  {showModerationBulk ? (
                    <th className={styles.thCheckbox} scope="col">
                      <span className={styles.srOnly}>Select</span>
                    </th>
                  ) : null}
                  <th scope="col">Scheduled</th>
                  <th scope="col">Site</th>
                  <th scope="col">Participants</th>
                  <th scope="col">Status</th>
                  <th scope="col">Completed</th>
                  <th className={styles.thActions} scope="col">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody>
                {data.map((e) => {
                  const { gm, am } = mapLinks(e.site.latitude, e.site.longitude);
                  const isCompleted = !!e.completedAt;
                  const modStatus = e.status ?? 'APPROVED';
                  return (
                    <tr key={e.id}>
                      {showModerationBulk ? (
                        <td className={styles.tdCheckbox}>
                          <input
                            type="checkbox"
                            checked={selectedIds.has(e.id)}
                            onChange={() => toggleRowSelected(e.id)}
                            aria-label={`Select ${e.title}`}
                          />
                        </td>
                      ) : null}
                      <td className={styles.cellDateTime}>
                        {formatDateTime(e.scheduledAt)}
                      </td>
                      <td>
                        <div className={styles.siteCell}>
                          <Link
                            href={`/dashboard/sites/${e.site.id}`}
                            className={styles.siteLink}
                          >
                            {e.site.latitude.toFixed(5)}, {e.site.longitude.toFixed(5)}
                          </Link>
                          <div className={styles.mapLinks}>
                            <a href={gm} target="_blank" rel="noopener noreferrer" className={styles.mapLink}>
                              Google Maps
                            </a>
                            <span className={styles.mapDivider}>·</span>
                            <a href={am} target="_blank" rel="noopener noreferrer" className={styles.mapLink}>
                              Apple Maps
                            </a>
                          </div>
                          {e.site.description ? (
                            <p className={styles.siteDesc}>{e.site.description}</p>
                          ) : null}
                        </div>
                      </td>
                      <td>{e.participantCount}</td>
                      <td>
                        <div className={styles.statusCell}>
                          <span
                            className={
                              isCompleted ? styles.statusCompleted : styles.statusUpcoming
                            }
                          >
                            {isCompleted ? 'Completed' : 'Upcoming'}
                          </span>
                          <span
                            className={
                              modStatus === 'PENDING'
                                ? styles.modStatusPending
                                : modStatus === 'DECLINED'
                                  ? styles.modStatusDeclined
                                  : styles.modStatusApproved
                            }
                          >
                            {modStatus}
                          </span>
                        </div>
                      </td>
                      <td className={styles.cellDateTime}>
                        {e.completedAt ? formatDateTime(e.completedAt) : '—'}
                      </td>
                      <td className={styles.tdActions}>
                        <Link href={`/dashboard/events/${e.id}`} className={styles.actionLink}>
                          View
                        </Link>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>

        <div className={styles.footer}>
          <p className={styles.meta}>
            {meta.total} event{meta.total !== 1 ? 's' : ''} · page {meta.page}
          </p>
          {meta.total > meta.limit && (
            <Pagination
              totalPages={Math.ceil(meta.total / meta.limit)}
              currentPage={meta.page}
              onPageChange={(p) => router.push(buildUrl({ page: p }))}
            />
          )}
        </div>
      </Card>

      <Snack snack={snack} onClose={() => setSnack(null)} />

      {bulkDeclineOpen ? (
        <div
          className={styles.modalBackdrop}
          role="presentation"
          onClick={(e) => {
            if (e.target !== e.currentTarget || bulkBusy) {
              return;
            }
            setBulkDeclineOpen(false);
            setBulkDeclineReason('');
            setBulkDeclineError(null);
          }}
        >
          <div
            ref={bulkDeclineCardRef}
            className={styles.modalCard}
            role="dialog"
            aria-modal="true"
            aria-labelledby="bulk-decline-title"
            onClick={(ev) => ev.stopPropagation()}
          >
            <h2 id="bulk-decline-title" className={styles.modalTitle}>
              Decline selected events
            </h2>
            <p id="bulk-decline-hint" className={styles.modalBody}>
              This reason applies to all {selectedIds.size} selected event{selectedIds.size !== 1 ? 's' : ''} (minimum
              3 characters).
            </p>
            <textarea
              ref={bulkDeclineReasonRef}
              className={styles.declineTextarea}
              value={bulkDeclineReason}
              onChange={(e) => {
                setBulkDeclineReason(e.target.value);
                setBulkDeclineError(null);
              }}
              disabled={bulkBusy}
              maxLength={2000}
              aria-invalid={bulkDeclineError ? true : undefined}
              aria-describedby={`bulk-decline-hint${bulkDeclineError ? ' bulk-decline-err' : ''}`}
            />
            {bulkDeclineError ? (
              <p id="bulk-decline-err" className={styles.fieldError} role="alert">
                {bulkDeclineError}
              </p>
            ) : null}
            <div className={styles.modalActions}>
              <Button
                type="button"
                variant="outline"
                disabled={bulkBusy}
                onClick={() => {
                  setBulkDeclineOpen(false);
                  setBulkDeclineReason('');
                  setBulkDeclineError(null);
                }}
              >
                Cancel
              </Button>
              <Button type="button" isLoading={bulkBusy} onClick={() => void submitBulkDecline()}>
                Decline all
              </Button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
