'use client';

import { useCallback, useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, EmptyState, Pagination, SectionState, useToast } from '@/components/ui';
import { ActionConfirmModal } from '@/features/reports/components/action-confirm-modal';
import { Can } from '@/lib/auth/rbac';
import { adminBrowserFetch } from '@/lib/api';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import { OPS_DEAD_LETTERS_PAGE_SIZE } from '../config';
import { useOperationsLive } from './operations-live-provider';
import styles from './operations-workspace.module.css';

type DeadLetterRow = {
  id: string;
  userNotificationId: string;
  deviceTokenSuffix: string;
  attempts: number;
  lastErrorCode: string | null;
  lastErrorMessage: string | null;
  lastAttemptAt: string | null;
  createdAt: string;
};

type DeadLettersResponse = {
  data: DeadLetterRow[];
  meta: { page: number; limit: number; total: number };
};

export function OperationsDeadLettersPanel({
  initialData,
  initialMeta,
  snapshotUpdatedAt,
}: {
  initialData: DeadLetterRow[];
  initialMeta: { page: number; limit: number; total: number };
  snapshotUpdatedAt?: string;
}) {
  const t = useTranslations('operations');
  const locale = useAdminBcp47Locale();
  const { showToast } = useToast();
  const { refresh } = useOperationsLive();
  const [rows, setRows] = useState(initialData);
  const [meta, setMeta] = useState(initialMeta);
  const [page, setPage] = useState(initialMeta.page);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [busyAction, setBusyAction] = useState<'requeue' | 'purge' | null>(null);
  const [confirmAction, setConfirmAction] = useState<'requeue' | 'purge' | null>(null);
  const [rowBusyId, setRowBusyId] = useState<string | null>(null);

  useEffect(() => {
    setRows(initialData);
    setMeta(initialMeta);
    setPage(initialMeta.page);
  }, [snapshotUpdatedAt, initialData, initialMeta]);

  const loadPage = useCallback(async (nextPage: number) => {
    setLoading(true);
    setError(null);
    try {
      const response = await adminBrowserFetch<DeadLettersResponse>(
        `/notifications/admin/dead-letters?page=${nextPage}&limit=${OPS_DEAD_LETTERS_PAGE_SIZE}`,
        { method: 'GET' },
      );
      setRows(response.data);
      setMeta(response.meta);
      setPage(response.meta.page);
    } catch (fetchError) {
      setError(fetchError instanceof Error ? fetchError.message : t('deadLetters.loadFailed'));
    } finally {
      setLoading(false);
    }
  }, [t]);

  async function runRequeue() {
    setBusyAction('requeue');
    try {
      const result = await adminBrowserFetch<{ requeued: number }>(
        '/notifications/admin/dead-letters/requeue',
        { method: 'POST' },
      );
      showToast({
        tone: 'success',
        title: t('deadLetters.requeueSuccessTitle'),
        message: t('deadLetters.requeueSuccessMessage', { count: result.requeued }),
      });
      setConfirmAction(null);
      refresh();
      await loadPage(page);
    } catch (fetchError) {
      showToast({
        tone: 'warning',
        title: t('deadLetters.requeueFailedTitle'),
        message: fetchError instanceof Error ? fetchError.message : t('deadLetters.requeueFailedMessage'),
      });
    } finally {
      setBusyAction(null);
    }
  }

  async function runPurge() {
    setBusyAction('purge');
    try {
      const result = await adminBrowserFetch<{ purged: number }>(
        '/notifications/admin/dead-letters/purge-terminal',
        { method: 'POST' },
      );
      showToast({
        tone: 'success',
        title: t('deadLetters.purgeSuccessTitle'),
        message: t('deadLetters.purgeSuccessMessage', { count: result.purged }),
      });
      setConfirmAction(null);
      refresh();
      await loadPage(1);
    } catch (fetchError) {
      showToast({
        tone: 'warning',
        title: t('deadLetters.purgeFailedTitle'),
        message: fetchError instanceof Error ? fetchError.message : t('deadLetters.purgeFailedMessage'),
      });
    } finally {
      setBusyAction(null);
    }
  }

  async function runRequeueOne(id: string) {
    setRowBusyId(id);
    try {
      const result = await adminBrowserFetch<{ requeued: boolean }>(
        `/notifications/admin/dead-letters/${id}/requeue`,
        { method: 'POST' },
      );
      showToast({
        tone: result.requeued ? 'success' : 'warning',
        title: result.requeued ? t('deadLetters.requeueOneSuccessTitle') : t('deadLetters.requeueOneSkippedTitle'),
        message: result.requeued
          ? t('deadLetters.requeueOneSuccessMessage')
          : t('deadLetters.requeueOneSkippedMessage'),
      });
      refresh();
      await loadPage(page);
    } catch (fetchError) {
      showToast({
        tone: 'warning',
        title: t('deadLetters.requeueFailedTitle'),
        message: fetchError instanceof Error ? fetchError.message : t('deadLetters.requeueFailedMessage'),
      });
    } finally {
      setRowBusyId(null);
    }
  }

  if (error) {
    return <SectionState variant="error" message={error} />;
  }

  return (
    <>
      <Can permission="operations:write">
        <div className={styles.deadLetterActions}>
          <Button
            variant="outline"
            disabled={busyAction != null || meta.total === 0}
            onClick={() => setConfirmAction('requeue')}
          >
            {t('deadLetters.requeueAll')}
          </Button>
          <Button
            variant="outline"
            disabled={busyAction != null || meta.total === 0}
            onClick={() => setConfirmAction('purge')}
          >
            {t('deadLetters.purgeTerminal')}
          </Button>
        </div>
      </Can>
      <p>{t('metrics.deadLettersTotal', { count: meta.total })}</p>
      {rows.length === 0 ? (
        <EmptyState title={t('deadLetters.emptyTitle')} description={t('deadLetters.emptyDescription')} />
      ) : (
        <ul className={styles.deadLetterList} aria-busy={loading}>
          {rows.map((row) => (
            <li key={row.id} className={styles.deadLetterItem}>
              <span className={styles.deadLetterCode}>{row.lastErrorCode ?? 'UNKNOWN'}</span>
              <span className={styles.deadLetterMeta}>
                {t('metrics.attempts', { count: row.attempts })} · token …{row.deviceTokenSuffix}
                {row.lastAttemptAt ? ` · ${formatAdminDateTime(row.lastAttemptAt, locale)}` : ''}
              </span>
              {row.lastErrorMessage ? (
                <span className={styles.deadLetterMessage}>{row.lastErrorMessage}</span>
              ) : null}
              <Can permission="operations:write">
                <div className={styles.deadLetterRowActions}>
                  <Button
                    variant="ghost"
                    disabled={rowBusyId != null || busyAction != null}
                    onClick={() => void runRequeueOne(row.id)}
                  >
                    {t('deadLetters.requeueOne')}
                  </Button>
                </div>
              </Can>
            </li>
          ))}
        </ul>
      )}
      {meta.total > meta.limit ? (
        <div className={styles.deadLetterPagination}>
          <Pagination
            compact
            totalPages={Math.ceil(meta.total / meta.limit)}
            currentPage={page}
            onPageChange={(nextPage) => void loadPage(nextPage)}
          />
        </div>
      ) : null}

      <ActionConfirmModal
        isOpen={confirmAction === 'requeue'}
        title={t('deadLetters.requeueConfirmTitle')}
        description={t('deadLetters.requeueConfirmDescription')}
        confirmLabel={t('deadLetters.requeueAll')}
        isConfirming={busyAction === 'requeue'}
        onCancel={() => setConfirmAction(null)}
        onConfirm={() => void runRequeue()}
      />
      <ActionConfirmModal
        isOpen={confirmAction === 'purge'}
        title={t('deadLetters.purgeConfirmTitle')}
        description={t('deadLetters.purgeConfirmDescription')}
        confirmLabel={t('deadLetters.purgeTerminal')}
        isConfirming={busyAction === 'purge'}
        onCancel={() => setConfirmAction(null)}
        onConfirm={() => void runPurge()}
      />
    </>
  );
}
