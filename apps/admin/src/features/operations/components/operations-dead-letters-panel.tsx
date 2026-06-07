'use client';

import { useCallback, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Pagination, SectionState } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/api';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
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

const PAGE_SIZE = 5;

export function OperationsDeadLettersPanel({
  initialData,
  initialMeta,
}: {
  initialData: DeadLetterRow[];
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
      const response = await adminBrowserFetch<DeadLettersResponse>(
        `/notifications/admin/dead-letters?page=${nextPage}&limit=${PAGE_SIZE}`,
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

  if (error) {
    return <SectionState variant="error" message={error} />;
  }

  return (
    <>
      <p>{t('metrics.deadLettersTotal', { count: meta.total })}</p>
      {rows.length > 0 ? (
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
            </li>
          ))}
        </ul>
      ) : null}
      {meta.total > meta.limit ? (
        <div className={styles.deadLetterPagination}>
          <Pagination
            totalPages={Math.ceil(meta.total / meta.limit)}
            currentPage={page}
            onPageChange={(nextPage) => void loadPage(nextPage)}
          />
        </div>
      ) : null}
    </>
  );
}
