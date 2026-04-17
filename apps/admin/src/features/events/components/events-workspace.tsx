'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Button, Card, Icon, Pagination } from '@/components/ui';
import type { CleanupEventRow, EventsStats } from '@/features/events/data/events-adapter';
import styles from './events-workspace.module.css';

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

  useEffect(() => {
    setData(initialData);
    setMeta(initialMeta);
  }, [initialData, initialMeta]);

  useEffect(() => {
    setStats(initialStats);
  }, [initialStats]);

  const status = searchParams.get('status') ?? '';
  const moderationStatus = searchParams.get('moderationStatus') ?? '';

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

  return (
    <div className={styles.layout}>
      <div className={styles.statsBar}>
        <motion.div
          className={styles.statCard}
          initial={{ opacity: 0, y: 4 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.2 }}
        >
          <span className={styles.statIcon}>
            <Icon name="calendar" size={18} aria-hidden />
          </span>
          <span className={styles.statValue}>{stats.total}</span>
          <span className={styles.statLabel}>Total events</span>
        </motion.div>
        <motion.div
          className={styles.statCard}
          initial={{ opacity: 0, y: 4 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.2, delay: 0.05 }}
        >
          <span className={styles.statIconUpcoming}>
            <Icon name="document-forward" size={18} aria-hidden />
          </span>
          <span className={styles.statValue}>{stats.upcoming}</span>
          <span className={styles.statLabel}>Upcoming</span>
        </motion.div>
        <motion.div
          className={styles.statCard}
          initial={{ opacity: 0, y: 4 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.2, delay: 0.1 }}
        >
          <span className={styles.statIconPending}>
            <Icon name="document-text" size={18} aria-hidden />
          </span>
          <span className={styles.statValue}>{stats.pending}</span>
          <span className={styles.statLabel}>Pending</span>
        </motion.div>
        <motion.div
          className={styles.statCard}
          initial={{ opacity: 0, y: 4 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.2, delay: 0.15 }}
        >
          <span className={styles.statIconCompleted}>
            <Icon name="check" size={18} aria-hidden />
          </span>
          <span className={styles.statValue}>{stats.completed}</span>
          <span className={styles.statLabel}>Completed</span>
        </motion.div>
        <motion.div
          className={styles.statCard}
          initial={{ opacity: 0, y: 4 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.2, delay: 0.2 }}
        >
          <span className={styles.statIconParticipants}>
            <Icon name="users" size={18} aria-hidden />
          </span>
          <span className={styles.statValue}>{totalParticipants}</span>
          <span className={styles.statLabel}>Participants</span>
        </motion.div>
      </div>

      <Card className={styles.tableCard}>
        <div className={styles.toolbar}>
          <div className={styles.filters}>
            <div className={styles.createHintBlock}>
              <Link href="/dashboard/sites" className={styles.createHint}>
                Create event from site
              </Link>
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

        <div className={styles.tableWrap}>
          {data.length === 0 ? (
            <div className={styles.empty}>No events match your filters.</div>
          ) : (
            <table className={styles.table}>
              <thead>
                <tr>
                  <th>Scheduled</th>
                  <th>Site</th>
                  <th>Participants</th>
                  <th>Status</th>
                  <th>Completed</th>
                  <th className={styles.thActions}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {data.map((e) => {
                  const { gm, am } = mapLinks(e.site.latitude, e.site.longitude);
                  const isCompleted = !!e.completedAt;
                  const modStatus = (e as { status?: string }).status ?? 'APPROVED';
                  return (
                    <tr key={e.id}>
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
    </div>
  );
}
