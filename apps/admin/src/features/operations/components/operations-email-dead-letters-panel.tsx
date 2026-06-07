'use client';

import { useCallback, useState } from 'react';
import { useTranslations } from 'next-intl';
import { EmptyState, Pagination, SectionState } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/api';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import { OPS_DEAD_LETTERS_PAGE_SIZE } from '../config';
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
}: {
  initialData: EmailDeadLetterRow[];
  initialMeta: { page: number; limit: number; total: number };
}) {
  const t = useTranslations('operations');
  const locale = useAdminBcp47Locale();
  const [rows, setRows] = useState(initialData);
  const [meta, setMeta] = useState(initialMeta);
  const [page, setPage] = useState(initialMeta.page);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

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

  if (error) {
    return <SectionState variant="error" message={error} />;
  }

  return (
    <>
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
    </>
  );
}
