'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Button, Card, Icon, Pagination } from '@/components/ui';
import type { SiteRow, SitesStats } from '@/features/sites/data/sites-adapter';
import styles from './sites-workspace.module.css';

const STATUS_OPTIONS = [
  { value: '', label: 'All statuses' },
  { value: 'REPORTED', label: 'Reported' },
  { value: 'VERIFIED', label: 'Verified' },
  { value: 'CLEANUP_SCHEDULED', label: 'Cleanup scheduled' },
  { value: 'IN_PROGRESS', label: 'In progress' },
  { value: 'CLEANED', label: 'Cleaned' },
  { value: 'DISPUTED', label: 'Disputed' },
];

function statusPillClass(status: string): string {
  const map: Record<string, string> = {
    REPORTED: styles.statusReported,
    VERIFIED: styles.statusVerified,
    CLEANUP_SCHEDULED: styles.statusScheduled,
    IN_PROGRESS: styles.statusInProgress,
    CLEANED: styles.statusCleaned,
    DISPUTED: styles.statusDisputed,
  };
  return `${styles.statusPill} ${map[status] ?? styles.statusDefault}`;
}

function formatStatus(status: string): string {
  return status.replace(/_/g, ' ').toLowerCase().replace(/\b\w/g, (c) => c.toUpperCase());
}

function mapLinks(lat: number, lng: number) {
  const gm = `https://www.google.com/maps?q=${lat},${lng}`;
  const am = `https://maps.apple.com/?q=${lat},${lng}`;
  return { gm, am };
}

type SitesWorkspaceProps = {
  initialData: SiteRow[];
  initialMeta: { total: number; page: number; limit: number };
  initialStats: SitesStats;
};

export function SitesWorkspace({
  initialData,
  initialMeta,
  initialStats,
}: SitesWorkspaceProps) {
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

  const buildUrl = (updates: { status?: string; page?: number }) => {
    const sp = new URLSearchParams(searchParams.toString());
    if (updates.status !== undefined) {
      if (updates.status) sp.set('status', updates.status);
      else sp.delete('status');
    }
    if (updates.page !== undefined) {
      if (updates.page > 1) sp.set('page', String(updates.page));
      else sp.delete('page');
    }
    const q = sp.toString();
    return `/dashboard/sites${q ? `?${q}` : ''}`;
  };

  const handleStatusChange = (value: string) => {
    router.push(buildUrl({ status: value, page: 1 }));
  };

  const refresh = () => router.refresh();

  const reportedCount = stats.byStatus['REPORTED'] ?? 0;
  const verifiedCount = stats.byStatus['VERIFIED'] ?? 0;
  const cleanedCount = stats.byStatus['CLEANED'] ?? 0;

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
            <Icon name="location" size={18} aria-hidden />
          </span>
          <span className={styles.statValue}>{stats.total}</span>
          <span className={styles.statLabel}>Total sites</span>
        </motion.div>
        <motion.div
          className={styles.statCard}
          initial={{ opacity: 0, y: 4 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.2, delay: 0.05 }}
        >
          <span className={styles.statIconReported}>
            <Icon name="document-text" size={18} aria-hidden />
          </span>
          <span className={styles.statValue}>{reportedCount}</span>
          <span className={styles.statLabel}>Reported</span>
        </motion.div>
        <motion.div
          className={styles.statCard}
          initial={{ opacity: 0, y: 4 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.2, delay: 0.1 }}
        >
          <span className={styles.statIconVerified}>
            <Icon name="check" size={18} aria-hidden />
          </span>
          <span className={styles.statValue}>{verifiedCount}</span>
          <span className={styles.statLabel}>Verified</span>
        </motion.div>
        <motion.div
          className={styles.statCard}
          initial={{ opacity: 0, y: 4 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.2, delay: 0.15 }}
        >
          <span className={styles.statIconCleaned}>
            <Icon name="shield" size={18} aria-hidden />
          </span>
          <span className={styles.statValue}>{cleanedCount}</span>
          <span className={styles.statLabel}>Cleaned</span>
        </motion.div>
      </div>

      <Card className={styles.tableCard}>
        <div className={styles.toolbar}>
          <div className={styles.filters}>
            <select
              value={status}
              onChange={(e) => handleStatusChange(e.target.value)}
              className={styles.filterSelect}
              aria-label="Filter by status"
            >
              {STATUS_OPTIONS.map((o) => (
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
            <div className={styles.empty}>No sites match your filters.</div>
          ) : (
            <table className={styles.table}>
              <thead>
                <tr>
                  <th>Location</th>
                  <th>Status</th>
                  <th>Reports</th>
                  <th className={styles.thActions}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {data.map((s) => {
                  const { gm, am } = mapLinks(s.latitude, s.longitude);
                  return (
                    <tr key={s.id}>
                      <td>
                        <div className={styles.locationCell}>
                          <Link href={`/dashboard/sites/${s.id}`} className={styles.coordsLink}>
                            {s.latitude.toFixed(5)}, {s.longitude.toFixed(5)}
                          </Link>
                          <div className={styles.mapLinks}>
                            <a
                              href={gm}
                              target="_blank"
                              rel="noopener noreferrer"
                              className={styles.mapLink}
                              aria-label="Open in Google Maps"
                            >
                              Google Maps
                            </a>
                            <span className={styles.mapDivider}>·</span>
                            <a
                              href={am}
                              target="_blank"
                              rel="noopener noreferrer"
                              className={styles.mapLink}
                              aria-label="Open in Apple Maps"
                            >
                              Apple Maps
                            </a>
                          </div>
                          {s.description ? (
                            <p className={styles.description}>{s.description}</p>
                          ) : null}
                        </div>
                      </td>
                      <td>
                        <span className={statusPillClass(s.status)}>
                          {formatStatus(s.status)}
                        </span>
                      </td>
                      <td>
                        {s.reportCount > 0 ? (
                          <Link
                            href={`/dashboard/reports?siteId=${s.id}`}
                            className={styles.reportsLink}
                          >
                            {s.reportCount}
                          </Link>
                        ) : (
                          <span className={styles.reportsCount}>{s.reportCount}</span>
                        )}
                      </td>
                      <td className={styles.tdActions}>
                        <Link href={`/dashboard/sites/${s.id}`} className={styles.actionLink}>
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
            {meta.total} site{meta.total !== 1 ? 's' : ''} · page {meta.page}
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
