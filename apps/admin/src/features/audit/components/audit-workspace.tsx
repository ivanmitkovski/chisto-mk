'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useCallback, useEffect, useState } from 'react';
import { motion, useReducedMotion } from 'framer-motion';
import { useTranslations } from 'next-intl';
import { Button, Card, DatePicker, Icon, PageHeader, Pagination, useToast } from '@/components/ui';
import { WorkspaceRefreshOverlay } from '@/features/admin-shell/components/workspace-refresh-overlay';
import { useWorkspaceRefresh } from '@/features/admin-shell/hooks/use-workspace-refresh';
import { useServerSyncedState } from '@/features/admin-shell/hooks/use-server-synced-state';
import type { AuditRow } from '@/features/audit/data/audit-adapter';
import { buildAuditExportCsv, validateAuditDateRange } from '@/features/audit/lib/audit-filters';
import { adminBrowserFetch } from '@/lib/api';
import { AuditTable } from './audit-table';
import styles from './audit-workspace.module.css';

type AuditWorkspaceProps = {
  initialData: AuditRow[];
  initialMeta: { page: number; limit: number; total: number };
};

export function AuditWorkspace({ initialData, initialMeta }: AuditWorkspaceProps) {
  const t = useTranslations('audit');
  const tCommon = useTranslations('common');
  const router = useRouter();
  const { refresh: refreshPage, isRefreshing } = useWorkspaceRefresh();
  const reduceMotion = useReducedMotion();
  const searchParams = useSearchParams();
  const [data] = useServerSyncedState(initialData);
  const [meta] = useServerSyncedState(initialMeta);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const { showToast } = useToast();

  const [action, setAction] = useState(searchParams.get('action') ?? '');
  const [resourceType, setResourceType] = useState(searchParams.get('resourceType') ?? '');
  const [resourceId, setResourceId] = useState(searchParams.get('resourceId') ?? '');
  const [actorId, setActorId] = useState(searchParams.get('actorId') ?? '');
  const [from, setFrom] = useState(searchParams.get('from') ?? '');
  const [to, setTo] = useState(searchParams.get('to') ?? '');
  const [dateError, setDateError] = useState<string | null>(null);
  const [exporting, setExporting] = useState(false);
  const translateDateError = (key: 'invalidDates' | 'fromBeforeTo') =>
    key === 'invalidDates' ? t('filters.invalidDates') : t('filters.fromBeforeTo');

  useEffect(() => {
    setAction(searchParams.get('action') ?? '');
    setResourceType(searchParams.get('resourceType') ?? '');
    setResourceId(searchParams.get('resourceId') ?? '');
    setActorId(searchParams.get('actorId') ?? '');
    setFrom(searchParams.get('from') ?? '');
    setTo(searchParams.get('to') ?? '');
    setDateError(null);
  }, [searchParams]);

  const buildUrl = useCallback(
    (updates: {
      action?: string;
      resourceType?: string;
      resourceId?: string;
      actorId?: string;
      from?: string;
      to?: string;
      page?: number;
    }) => {
      const sp = new URLSearchParams(searchParams.toString());
      const keys = ['action', 'resourceType', 'resourceId', 'actorId', 'from', 'to'] as const;
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
    const validationError = validateAuditDateRange(from, to, translateDateError);
    if (validationError) {
      setDateError(validationError);
      return;
    }
    setDateError(null);
    router.push(buildUrl({ action, resourceType, resourceId, actorId, from, to, page: 1 }));
  }, [router, buildUrl, action, resourceType, resourceId, actorId, from, to, translateDateError]);

  const clearFilters = useCallback(() => {
    setAction('');
    setResourceType('');
    setResourceId('');
    setActorId('');
    setFrom('');
    setTo('');
    setDateError(null);
    router.push('/dashboard/audit');
  }, [router]);

  const copyId = (id: string) => {
    navigator.clipboard.writeText(id).then(() => {
      showToast({ tone: 'success', title: tCommon('copied'), message: tCommon('idCopiedToClipboard') });
    });
  };

  const hasFilters = !!(action || resourceType || resourceId || actorId || from || to);

  const exportCsv = useCallback(async () => {
    const validationError = validateAuditDateRange(from, to, translateDateError);
    if (validationError) {
      setDateError(validationError);
      showToast({ tone: 'warning', title: tCommon('exportBlocked'), message: validationError });
      return;
    }

    setExporting(true);
    try {
      const sp = new URLSearchParams({ page: '1', limit: '500' });
      if (action) sp.set('action', action);
      if (resourceType) sp.set('resourceType', resourceType);
      if (resourceId) sp.set('resourceId', resourceId);
      if (actorId) sp.set('actorId', actorId);
      if (from) sp.set('from', from);
      if (to) sp.set('to', to);

      const result = await adminBrowserFetch<{ data: AuditRow[] }>(`/admin/audit?${sp.toString()}`);
      const csv = buildAuditExportCsv(result.data);
      const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' });
      const url = URL.createObjectURL(blob);
      const anchor = document.createElement('a');
      anchor.href = url;
      anchor.download = `audit-export-${new Date().toISOString().slice(0, 10)}.csv`;
      anchor.click();
      URL.revokeObjectURL(url);
      showToast({
        tone: 'success',
        title: tCommon('exportReady'),
        message: tCommon('exportedRows', { count: result.data.length }),
      });
    } catch (error) {
      showToast({
        tone: 'warning',
        title: tCommon('exportFailed'),
        message: error instanceof Error ? error.message : tCommon('exportFailed'),
      });
    } finally {
      setExporting(false);
    }
  }, [action, actorId, from, resourceId, resourceType, showToast, tCommon, to, translateDateError]);

  return (
    <WorkspaceRefreshOverlay isRefreshing={isRefreshing}>
    <div className={styles.layout}>
      <PageHeader title={t('pageTitle')} description={t('pageDescription')} />
      <a href="#audit-table" className="skipLink">
        {t('skipToTable')}
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
            {hasFilters ? t('stats.entriesFiltered') : t('stats.totalEntries')}
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
          <span className={styles.statLabel}>{t('stats.pages')}</span>
        </motion.div>
      </div>

      <Card className={styles.filtersCard}>
        <span className={styles.filtersLabel}>{t('filters.label')}</span>
        <div className={styles.filtersGrid}>
          <div className={styles.field}>
            <label htmlFor="audit-action">{t('filters.action')}</label>
            <input
              id="audit-action"
              type="text"
              placeholder={t('filters.actionPlaceholder')}
              value={action}
              onChange={(e) => setAction(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && applyFilters()}
              className={styles.input}
            />
          </div>
          <div className={styles.field}>
            <label htmlFor="audit-resource">{t('filters.resourceType')}</label>
            <input
              id="audit-resource"
              type="text"
              placeholder={t('filters.resourceTypePlaceholder')}
              value={resourceType}
              onChange={(e) => setResourceType(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && applyFilters()}
              className={styles.input}
            />
          </div>
          <div className={styles.field}>
            <label htmlFor="audit-resource-id">{t('filters.resourceId')}</label>
            <input
              id="audit-resource-id"
              type="text"
              placeholder={t('filters.resourceIdPlaceholder')}
              value={resourceId}
              onChange={(e) => setResourceId(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && applyFilters()}
              className={styles.input}
            />
          </div>
          <div className={styles.field}>
            <label htmlFor="audit-actor">{t('filters.actorId')}</label>
            <input
              id="audit-actor"
              type="text"
              placeholder={t('filters.actorIdPlaceholder')}
              value={actorId}
              onChange={(e) => setActorId(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && applyFilters()}
              className={styles.input}
            />
          </div>
          <DatePicker
            label={t('filters.from')}
            value={from}
            onValueChange={setFrom}
            size="sm"
            className={styles.datePicker}
          />
          <DatePicker
            label={t('filters.to')}
            value={to}
            onValueChange={setTo}
            size="sm"
            className={styles.datePicker}
          />
        </div>
        {dateError ? <p className={styles.dateError} role="alert">{dateError}</p> : null}
        <div className={styles.filterActions}>
          <Button onClick={applyFilters}>{t('filters.apply')}</Button>
          <Button variant="outline" onClick={clearFilters}>
            {t('filters.clear')}
          </Button>
        </div>
      </Card>

      <Card className={styles.tableCard} id="audit-table">
        <div className={styles.toolbar}>
          <span className={styles.toolbarHint}>
            {t('table.entriesMeta', { count: meta.total, page: meta.page })}
          </span>
          <Button variant="outline" size="sm" onClick={() => void exportCsv()} disabled={exporting} aria-busy={exporting}>
            {exporting ? tCommon('exporting') : tCommon('exportCsv')}
          </Button>
          <Button variant="outline" size="sm" onClick={() => refreshPage()}>
            {tCommon('refresh')}
          </Button>
        </div>

        <AuditTable
          data={data}
          expandedId={expandedId}
          onToggleExpanded={(id) => setExpandedId((current) => (current === id ? null : id))}
          onCopyId={copyId}
        />

        {meta.total > meta.limit && (
          <div className={styles.footer}>
            <p className={styles.meta}>
              {t('table.entriesMeta', { count: meta.total, page: meta.page })}
            </p>
            <Pagination
              totalPages={Math.ceil(meta.total / meta.limit)}
              currentPage={meta.page}
              onPageChange={(p) => router.push(buildUrl({ page: p }))}
            />
          </div>
        )}
      </Card>
    </div>
    </WorkspaceRefreshOverlay>
  );
}
