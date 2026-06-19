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

type EmailDeadLetterRow = {
  id: string;
  userId: string;
  templateId: string;
  attempts: number;
  lastError: string | null;
  lastAttemptAt: string | null;
  createdAt: string;
};

type EmailDeadLettersResponse = {
  data: EmailDeadLetterRow[];
  meta: { page: number; limit: number; total: number };
};

export function OperationsEmailDeadLettersPanel({
  initialData,
  initialMeta,
  snapshotUpdatedAt,
}: {
  initialData: EmailDeadLetterRow[];
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
      const response = await adminBrowserFetch<EmailDeadLettersResponse>(
        `/admin/comms/email-dead-letters?page=${nextPage}&limit=${OPS_DEAD_LETTERS_PAGE_SIZE}`,
        { method: 'GET' },
      );
      setRows(response.data);
      setMeta(response.meta);
      setPage(response.meta.page);
    } catch (fetchError) {
      setError(fetchError instanceof Error ? fetchError.message : t('emailDeadLetters.loadFailed'));
    } finally {
      setLoading(false);
    }
  }, [t]);

  async function runRequeue() {
    setBusyAction('requeue');
    try {
      const result = await adminBrowserFetch<{ requeued: number }>(
        '/admin/comms/email-dead-letters/requeue',
        { method: 'POST' },
      );
      showToast({
        tone: 'success',
        title: t('emailDeadLetters.requeueSuccessTitle'),
        message: t('emailDeadLetters.requeueSuccessMessage', { count: result.requeued }),
      });
      setConfirmAction(null);
      refresh();
      await loadPage(page);
    } catch (fetchError) {
      showToast({
        tone: 'warning',
        title: t('emailDeadLetters.requeueFailedTitle'),
        message: fetchError instanceof Error ? fetchError.message : t('emailDeadLetters.requeueFailedMessage'),
      });
    } finally {
      setBusyAction(null);
    }
  }

  async function runPurge() {
    setBusyAction('purge');
    try {
      const result = await adminBrowserFetch<{ purged: number }>(
        '/admin/comms/email-dead-letters/purge-terminal',
        { method: 'POST' },
      );
      showToast({
        tone: 'success',
        title: t('emailDeadLetters.purgeSuccessTitle'),
        message: t('emailDeadLetters.purgeSuccessMessage', { count: result.purged }),
      });
      setConfirmAction(null);
      refresh();
      await loadPage(1);
    } catch (fetchError) {
      showToast({
        tone: 'warning',
        title: t('emailDeadLetters.purgeFailedTitle'),
        message: fetchError instanceof Error ? fetchError.message : t('emailDeadLetters.purgeFailedMessage'),
      });
    } finally {
      setBusyAction(null);
    }
  }

  async function runRequeueOne(id: string) {
    setRowBusyId(id);
    try {
      const result = await adminBrowserFetch<{ requeued: boolean }>(
        `/admin/comms/email-dead-letters/${id}/requeue`,
        { method: 'POST' },
      );
      showToast({
        tone: result.requeued ? 'success' : 'warning',
        title: result.requeued ? t('emailDeadLetters.requeueOneSuccessTitle') : t('emailDeadLetters.requeueOneSkippedTitle'),
        message: result.requeued
          ? t('emailDeadLetters.requeueOneSuccessMessage')
          : t('emailDeadLetters.requeueOneSkippedMessage'),
      });
      refresh();
      await loadPage(page);
    } catch (fetchError) {
      showToast({
        tone: 'warning',
        title: t('emailDeadLetters.requeueFailedTitle'),
        message: fetchError instanceof Error ? fetchError.message : t('emailDeadLetters.requeueFailedMessage'),
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
      <Can permission="comms:write">
        <div className={styles.deadLetterActions}>
          <Button
            variant="outline"
            disabled={busyAction != null || meta.total === 0}
            onClick={() => setConfirmAction('requeue')}
          >
            {t('emailDeadLetters.requeueAll')}
          </Button>
          <Button
            variant="outline"
            disabled={busyAction != null || meta.total === 0}
            onClick={() => setConfirmAction('purge')}
          >
            {t('emailDeadLetters.purgeTerminal')}
          </Button>
        </div>
      </Can>
      <p>{t('metrics.emailDeadLettersTotal', { count: meta.total })}</p>
      {rows.length === 0 ? (
        <EmptyState title={t('emailDeadLetters.emptyTitle')} description={t('emailDeadLetters.emptyDescription')} />
      ) : (
        <ul className={styles.deadLetterList} aria-busy={loading}>
          {rows.map((row) => (
            <li key={row.id} className={styles.deadLetterItem}>
              <span className={styles.deadLetterCode}>{row.templateId}</span>
              <span className={styles.deadLetterMeta}>
                {t('metrics.attempts', { count: row.attempts })} · user {row.userId.slice(0, 8)}…
                {row.lastAttemptAt ? ` · ${formatAdminDateTime(row.lastAttemptAt, locale)}` : ''}
              </span>
              {row.lastError ? <span className={styles.deadLetterMessage}>{row.lastError}</span> : null}
              <Can permission="comms:write">
                <div className={styles.deadLetterRowActions}>
                  <Button
                    variant="ghost"
                    disabled={rowBusyId != null || busyAction != null}
                    onClick={() => void runRequeueOne(row.id)}
                  >
                    {t('emailDeadLetters.requeueOne')}
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
        title={t('emailDeadLetters.requeueConfirmTitle')}
        description={t('emailDeadLetters.requeueConfirmDescription')}
        confirmLabel={t('emailDeadLetters.requeueAll')}
        isConfirming={busyAction === 'requeue'}
        onCancel={() => setConfirmAction(null)}
        onConfirm={() => void runRequeue()}
      />
      <ActionConfirmModal
        isOpen={confirmAction === 'purge'}
        title={t('emailDeadLetters.purgeConfirmTitle')}
        description={t('emailDeadLetters.purgeConfirmDescription')}
        confirmLabel={t('emailDeadLetters.purgeTerminal')}
        isConfirming={busyAction === 'purge'}
        onCancel={() => setConfirmAction(null)}
        onConfirm={() => void runPurge()}
      />
    </>
  );
}
