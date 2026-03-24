'use client';

import { Fragment } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { useCallback, useEffect, useState } from 'react';
import { motion, useReducedMotion } from 'framer-motion';
import { Button, Card, Icon, Pagination, Snack } from '@/components/ui';
import type { AuditRow } from '@/features/audit/data/audit-adapter';
import styles from './audit-workspace.module.css';

function formatAction(action: string): string {
  return action.replace(/_/g, ' ').toLowerCase().replace(/\b\w/g, (c) => c.toUpperCase());
}

function actionPillClass(action: string): string {
  if (action.includes('LOGIN')) return styles.pillAuth;
  if (action.includes('CREATED') || action.includes('CREATE')) return styles.pillCreate;
  if (action.includes('UPDATED') || action.includes('UPDATE')) return styles.pillUpdate;
  if (action.includes('DELETED') || action.includes('DELETE') || action.includes('REJECT')) return styles.pillDelete;
  if (action.includes('MERGE')) return styles.pillMerge;
  if (action.includes('REVOKE') || action.includes('FAILED')) return styles.pillWarning;
  return styles.pillDefault;
}

function resourceHref(row: AuditRow): string | null {
  if (!row.resourceId) return null;
  switch (row.resourceType) {
    case 'User':
      return `/dashboard/users/${row.resourceId}`;
    case 'Report':
      return `/dashboard/reports/${row.resourceId}`;
    case 'Site':
      return `/dashboard/sites/${row.resourceId}`;
    case 'CleanupEvent':
      return `/dashboard/events/${row.resourceId}`;
    default:
      return null;
  }
}

function truncateId(id: string | null, max = 12): string {
  if (!id) return '—';
  if (id.length <= max) return id;
  return `${id.slice(0, 6)}…${id.slice(-4)}`;
}

type AuditWorkspaceProps = {
  initialData: AuditRow[];
  initialMeta: { page: number; limit: number; total: number };
};

export function AuditWorkspace({ initialData, initialMeta }: AuditWorkspaceProps) {
  const router = useRouter();
  const reduceMotion = useReducedMotion();
  const searchParams = useSearchParams();
  const [data, setData] = useState(initialData);
  const [meta, setMeta] = useState(initialMeta);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [snack, setSnack] = useState<{ tone: 'success'; message: string } | null>(null);

  const [action, setAction] = useState(searchParams.get('action') ?? '');
  const [resourceType, setResourceType] = useState(searchParams.get('resourceType') ?? '');
  const [actorId, setActorId] = useState(searchParams.get('actorId') ?? '');
  const [from, setFrom] = useState(searchParams.get('from') ?? '');
  const [to, setTo] = useState(searchParams.get('to') ?? '');

  useEffect(() => {
    setAction(searchParams.get('action') ?? '');
    setResourceType(searchParams.get('resourceType') ?? '');
    setActorId(searchParams.get('actorId') ?? '');
    setFrom(searchParams.get('from') ?? '');
    setTo(searchParams.get('to') ?? '');
  }, [searchParams]);

  useEffect(() => {
    setData(initialData);
    setMeta(initialMeta);
  }, [initialData, initialMeta]);

  const buildUrl = useCallback(
    (updates: {
      action?: string;
      resourceType?: string;
      actorId?: string;
      from?: string;
      to?: string;
      page?: number;
    }) => {
      const sp = new URLSearchParams(searchParams.toString());
      const keys = ['action', 'resourceType', 'actorId', 'from', 'to'] as const;
      keys.forEach((k) => {
        const v = updates[k];
        if (v !== undefined) {
          if (v) sp.set(k, v);
          else sp.delete(k);
        }
      });
      if (updates.page !== undefined) {
        if (updates.page > 1) sp.set('page', String(updates.page));
        else sp.delete('page');
      }
      const q = sp.toString();
      return `/dashboard/audit${q ? `?${q}` : ''}`;
    },
    [searchParams],
  );

  const applyFilters = useCallback(() => {
    router.push(buildUrl({ action, resourceType, actorId, from, to, page: 1 }));
  }, [router, buildUrl, action, resourceType, actorId, from, to]);

  const clearFilters = useCallback(() => {
    setAction('');
    setResourceType('');
    setActorId('');
    setFrom('');
    setTo('');
    router.push('/dashboard/audit');
  }, [router]);

  const copyId = (id: string) => {
    navigator.clipboard.writeText(id).then(() => {
      setSnack({ tone: 'success', message: 'ID copied to clipboard' });
      setTimeout(() => setSnack(null), 2000);
    });
  };

  const hasFilters = !!(action || resourceType || actorId || from || to);

  return (
    <div className={styles.layout}>
      <a href="#audit-table" className="skipLink">
        Skip to audit table
      </a>
      <div className={styles.statsBar}>
        <motion.div
          className={styles.statCard}
          initial={reduceMotion ? false : { opacity: 0, y: 4 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: reduceMotion ? 0 : 0.2 }}
        >
          <span className={styles.statIcon}>
            <Icon name="scroll-text" size={18} aria-hidden />
          </span>
          <span className={styles.statValue}>{meta.total}</span>
          <span className={styles.statLabel}>
            {hasFilters ? 'Entries (filtered)' : 'Total entries'}
          </span>
        </motion.div>
        <motion.div
          className={styles.statCard}
          initial={reduceMotion ? false : { opacity: 0, y: 4 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: reduceMotion ? 0 : 0.2, delay: reduceMotion ? 0 : 0.05 }}
        >
          <span className={styles.statIconPage}>
            <Icon name="document-text" size={18} aria-hidden />
          </span>
          <span className={styles.statValue}>
            {Math.ceil(meta.total / meta.limit) || 1}
          </span>
          <span className={styles.statLabel}>Pages</span>
        </motion.div>
      </div>

      <Card className={styles.filtersCard}>
        <span className={styles.filtersLabel}>Filters</span>
        <div className={styles.filtersGrid}>
          <div className={styles.field}>
            <label htmlFor="audit-action">Action</label>
            <input
              id="audit-action"
              type="text"
              placeholder="e.g. USER_UPDATED"
              value={action}
              onChange={(e) => setAction(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && applyFilters()}
              className={styles.input}
            />
          </div>
          <div className={styles.field}>
            <label htmlFor="audit-resource">Resource type</label>
            <input
              id="audit-resource"
              type="text"
              placeholder="e.g. User, Report"
              value={resourceType}
              onChange={(e) => setResourceType(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && applyFilters()}
              className={styles.input}
            />
          </div>
          <div className={styles.field}>
            <label htmlFor="audit-actor">Actor ID</label>
            <input
              id="audit-actor"
              type="text"
              placeholder="User ID"
              value={actorId}
              onChange={(e) => setActorId(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && applyFilters()}
              className={styles.input}
            />
          </div>
          <div className={styles.field}>
            <label htmlFor="audit-from">From</label>
            <input
              id="audit-from"
              type="date"
              value={from}
              onChange={(e) => setFrom(e.target.value)}
              className={styles.input}
            />
          </div>
          <div className={styles.field}>
            <label htmlFor="audit-to">To</label>
            <input
              id="audit-to"
              type="date"
              value={to}
              onChange={(e) => setTo(e.target.value)}
              className={styles.input}
            />
          </div>
        </div>
        <div className={styles.filterActions}>
          <Button onClick={applyFilters}>Apply filters</Button>
          <Button variant="outline" onClick={clearFilters}>
            Clear
          </Button>
        </div>
      </Card>

      <Card className={styles.tableCard} id="audit-table">
        <div className={styles.toolbar}>
          <span className={styles.toolbarHint}>
            {meta.total} entr{meta.total !== 1 ? 'ies' : 'y'} · page {meta.page}
          </span>
          <Button variant="outline" size="sm" onClick={() => router.refresh()}>
            Refresh
          </Button>
        </div>

        <div className={styles.tableWrap}>
          {data.length === 0 ? (
            <div className={styles.empty}>No audit entries match your filters.</div>
          ) : (
            <table className={styles.table}>
              <thead>
                <tr>
                  <th>Time</th>
                  <th>Action</th>
                  <th>Resource</th>
                  <th>Actor</th>
                  <th className={styles.thDetails}></th>
                </tr>
              </thead>
              <tbody>
                {data.map((row) => {
                  const href = resourceHref(row);
                  const isExpanded = expandedId === row.id;
                  const hasMetadata = row.metadata != null;
                  return (
                    <Fragment key={row.id}>
                      <tr className={styles.row}>
                        <td className={styles.cellTime}>
                          {new Date(row.createdAt).toLocaleString(undefined, {
                            dateStyle: 'medium',
                            timeStyle: 'short',
                          })}
                        </td>
                        <td>
                          <span className={actionPillClass(row.action)}>
                            {formatAction(row.action)}
                          </span>
                        </td>
                        <td>
                          <div className={styles.resourceCell}>
                            <span className={styles.resourceType}>{row.resourceType}</span>
                            {row.resourceId && (
                              <>
                                <span className={styles.resourceSep}>·</span>
                                {href ? (
                                  <Link href={href} className={styles.resourceLink}>
                                    {truncateId(row.resourceId)}
                                  </Link>
                                ) : (
                                  <button
                                    type="button"
                                    className={styles.resourceIdBtn}
                                    onClick={() => copyId(row.resourceId!)}
                                    title="Copy ID"
                                  >
                                    {truncateId(row.resourceId)}
                                  </button>
                                )}
                              </>
                            )}
                          </div>
                        </td>
                        <td>
                          <span className={styles.actor}>
                            {row.actorEmail ?? <em>System</em>}
                          </span>
                        </td>
                        <td className={styles.tdDetails}>
                          {hasMetadata && (
                            <button
                              type="button"
                              className={styles.detailsBtn}
                              onClick={() => setExpandedId(isExpanded ? null : row.id)}
                              aria-expanded={isExpanded}
                            >
                              {isExpanded ? 'Hide' : 'Details'}
                            </button>
                          )}
                        </td>
                      </tr>
                      {isExpanded && hasMetadata && (
                        <tr className={styles.metaRow}>
                          <td colSpan={5}>
                            <pre className={styles.metaPre}>
                              {JSON.stringify(row.metadata, null, 2)}
                            </pre>
                          </td>
                        </tr>
                      )}
                    </Fragment>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>

        {meta.total > meta.limit && (
          <div className={styles.footer}>
            <p className={styles.meta}>
              {meta.total} entr{meta.total !== 1 ? 'ies' : 'y'} · page {meta.page}
            </p>
            <Pagination
              totalPages={Math.ceil(meta.total / meta.limit)}
              currentPage={meta.page}
              onPageChange={(p) => router.push(buildUrl({ page: p }))}
            />
          </div>
        )}
      </Card>

      {snack && (
        <Snack
          snack={{ tone: snack.tone, title: snack.message, message: '' }}
          onClose={() => setSnack(null)}
        />
      )}
    </div>
  );
}
