'use client';

import { useCallback, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Card, Input, Pagination, SectionState, useToast } from '@/components/ui';
import { Can } from '@/lib/auth/rbac';
import { adminBrowserFetch } from '@/lib/api';
import type { UserPointLedgerEntry } from '@/features/gamification';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import styles from './user-points-panel.module.css';

type UserPointsPanelProps = {
  userId: string;
  initialBalance: number;
  initialLedger: UserPointLedgerEntry[];
  initialTotal: number;
  initialPage?: number;
  pageSize?: number;
  loadError?: string | null;
};

export function UserPointsPanel({
  userId,
  initialBalance,
  initialLedger,
  initialTotal,
  initialPage = 1,
  pageSize = 20,
  loadError = null,
}: UserPointsPanelProps) {
  const t = useTranslations('users');
  const tCommon = useTranslations('common');
  const locale = useAdminBcp47Locale();
  const [balance, setBalance] = useState(initialBalance);
  const [ledger, setLedger] = useState(initialLedger);
  const [total, setTotal] = useState(initialTotal);
  const [page, setPage] = useState(initialPage);
  const [ledgerLoading, setLedgerLoading] = useState(false);
  const [delta, setDelta] = useState('');
  const [reasonCode, setReasonCode] = useState('admin_adjustment');
  const [note, setNote] = useState('');
  const [busy, setBusy] = useState(false);
  const { showToast } = useToast();

  const loadLedgerPage = useCallback(
    async (nextPage: number) => {
      setLedgerLoading(true);
      try {
        const refreshed = await adminBrowserFetch<{
          data: UserPointLedgerEntry[];
          meta: { total: number; page: number; limit: number };
        }>(`/admin/gamification/users/${encodeURIComponent(userId)}/points?limit=${pageSize}&page=${nextPage}`);
        setLedger(refreshed.data);
        setTotal(refreshed.meta.total);
        setPage(refreshed.meta.page);
      } finally {
        setLedgerLoading(false);
      }
    },
    [pageSize, userId],
  );

  async function adjustPoints() {
    const parsedDelta = Number(delta);
    if (!Number.isFinite(parsedDelta) || parsedDelta === 0) return;
    setBusy(true);
    try {
      await adminBrowserFetch(`/admin/gamification/users/${encodeURIComponent(userId)}/points/adjust`, {
        method: 'POST',
        body: { delta: parsedDelta, reasonCode, note: note.trim() || undefined },
      });
      await loadLedgerPage(1);
      if (ledger[0]) {
        setBalance(ledger[0].balanceAfter);
      } else {
        setBalance((b) => b + parsedDelta);
      }
      setDelta('');
      setNote('');
      showToast({
        tone: 'success',
        title: t('detail.pointsAdjustedTitle'),
        message: t('detail.pointsAdjustedMessage'),
      });
    } catch (error) {
      showToast({
        tone: 'warning',
        title: t('detail.points.adjustFailed'),
        message: error instanceof Error ? error.message : t('detail.points.adjustFailedMessage'),
      });
    } finally {
      setBusy(false);
    }
  }

  if (loadError) {
    return <SectionState variant="error" message={loadError} />;
  }

  return (
    <Card padding="md">
      <p className={styles.balance}>{t('detail.points.currentBalance', { balance })}</p>
      <Can permission="gamification:write">
        <div className={styles.form}>
          <Input
            label={t('detail.points.delta')}
            type="number"
            value={delta}
            onChange={(e) => setDelta(e.target.value)}
          />
          <Input
            label={t('detail.points.reasonCode')}
            value={reasonCode}
            onChange={(e) => setReasonCode(e.target.value)}
          />
          <Input
            label={t('detail.points.noteOptional')}
            value={note}
            onChange={(e) => setNote(e.target.value)}
          />
          <Button disabled={busy || !delta} onClick={() => void adjustPoints()}>
            {t('detail.points.adjustPoints')}
          </Button>
        </div>
      </Can>
      <h3>{t('detail.points.recentLedger', { count: total })}</h3>
      <table className={styles.table}>
        <thead>
          <tr>
            <th>{t('detail.points.when')}</th>
            <th>{t('detail.points.deltaCol')}</th>
            <th>{t('detail.points.reason')}</th>
            <th>{t('detail.points.balance')}</th>
          </tr>
        </thead>
        <tbody>
          {ledger.map((entry) => (
            <tr key={entry.id}>
              <td>{formatAdminDateTime(entry.createdAt, locale)}</td>
              <td>{entry.delta > 0 ? `+${entry.delta}` : entry.delta}</td>
              <td>{entry.reasonCode}</td>
              <td>{entry.balanceAfter}</td>
            </tr>
          ))}
        </tbody>
      </table>
      {ledger.length === 0 && !ledgerLoading ? <p className={styles.empty}>{tCommon('noData')}</p> : null}
      {total > pageSize ? (
        <div className={styles.footer}>
          <Pagination
            totalPages={Math.ceil(total / pageSize)}
            currentPage={page}
            onPageChange={(nextPage) => void loadLedgerPage(nextPage)}
          />
        </div>
      ) : null}
    </Card>
  );
}
