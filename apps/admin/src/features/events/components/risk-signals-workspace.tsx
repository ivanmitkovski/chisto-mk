'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Select, useToast } from '@/components/ui';
import { Can } from '@/lib/auth/rbac';
import { adminBrowserFetch } from '@/lib/api';
import { useAdminBcp47Locale } from '@/lib/i18n';
import { subscribeCheckInRiskSignal } from '@/lib/realtime';
import { formatEventDateTime } from '../lib/events-display';
import { formatRiskSignalResolution } from '../lib/risk-signal-display';
import type { CheckInRiskSignalRow, CheckInRiskSignalStatusFilter } from '../data/events-adapter';
import { RiskSignalDetailsCell, RiskSignalEventCell } from './risk-signal-details-cell';
import styles from './risk-signals-page.module.css';

type RiskSignalsWorkspaceProps = {
  initialResult: {
    data: CheckInRiskSignalRow[];
    page: number;
    limit: number;
    total: number;
  };
  statusFilter: CheckInRiskSignalStatusFilter;
};

export function RiskSignalsWorkspace({ initialResult, statusFilter }: RiskSignalsWorkspaceProps) {
  const router = useRouter();
  const { showToast } = useToast();
  const locale = useAdminBcp47Locale();
  const t = useTranslations('events');
  const tRisk = useTranslations('events.riskSignals');
  const tCommon = useTranslations('common');
  const [busyId, setBusyId] = useState<string | null>(null);
  const totalPages = Math.max(1, Math.ceil(initialResult.total / initialResult.limit));

  const riskT = (
    key: 'signalFarFromSite' | 'resolutionDismissed' | 'resolutionResolved' | 'resolutionClosed',
  ) => tRisk(key);

  useEffect(() => {
    return subscribeCheckInRiskSignal(() => {
      router.refresh();
    });
  }, [router]);

  async function handleAction(id: string, action: 'resolve' | 'dismiss') {
    setBusyId(id);
    try {
      await adminBrowserFetch(`/admin/cleanup-events/check-in-risk-signals/${encodeURIComponent(id)}`, {
        method: 'PATCH',
        body: { action },
      });
      showToast({
        tone: 'success',
        title: action === 'resolve' ? tRisk('toast.resolvedTitle') : tRisk('toast.dismissedTitle'),
        message: tRisk('toast.updatedMessage'),
      });
      router.refresh();
    } catch (error) {
      showToast({
        tone: 'warning',
        title: tRisk('toast.failedTitle'),
        message: error instanceof Error ? error.message : tRisk('toast.failedMessage'),
      });
    } finally {
      setBusyId(null);
    }
  }

  function pageHref(page: number): string {
    const params = new URLSearchParams();
    if (statusFilter !== 'active') params.set('status', statusFilter);
    if (page > 1) params.set('page', String(page));
    const q = params.toString();
    return `/dashboard/events/risk-signals${q ? `?${q}` : ''}`;
  }

  return (
    <div className={styles.layout}>
      <p className={styles.riskSignalsIntro}>{tRisk('intro')}</p>
      <p className={styles.backToEvents}>
        <Link href="/dashboard/events" className={styles.createHint}>
          ← {t('backToEvents')}
        </Link>
      </p>

      <div className={styles.filtersRow}>
        <Select
          label={tRisk('statusFilter')}
          value={statusFilter}
          options={[
            { value: 'active', label: tRisk('statusActive') },
            { value: 'resolved', label: tRisk('statusResolved') },
            { value: 'all', label: tRisk('statusAll') },
          ]}
          onChange={(event) => {
            const next = event.target.value as CheckInRiskSignalStatusFilter;
            const params = new URLSearchParams();
            if (next !== 'active') params.set('status', next);
            const q = params.toString();
            router.push(`/dashboard/events/risk-signals${q ? `?${q}` : ''}`);
          }}
        />
      </div>

      <div className={styles.tableCard}>
        <div className={styles.tableWrap}>
          {initialResult.data.length === 0 ? (
            <div className={styles.empty}>{tRisk('empty')}</div>
          ) : (
            <table className={styles.table}>
              <thead>
                <tr>
                  <th>{tRisk('columns.recorded')}</th>
                  <th>{tRisk('columns.expires')}</th>
                  <th>{tRisk('columns.signal')}</th>
                  <th>{tRisk('columns.event')}</th>
                  <th>{tRisk('columns.attendee')}</th>
                  <th>{tRisk('columns.actions')}</th>
                </tr>
              </thead>
              <tbody>
                {initialResult.data.map((row) => (
                  <tr key={row.id}>
                    <td className={styles.cellDateTime}>{formatEventDateTime(row.createdAt, locale)}</td>
                    <td className={styles.cellDateTime}>{formatEventDateTime(row.expiresAt, locale)}</td>
                    <td>
                      <RiskSignalDetailsCell row={row} />
                    </td>
                    <td>
                      <RiskSignalEventCell row={row} />
                    </td>
                    <td>{row.userDisplayName || row.userId}</td>
                    <td>
                      {!row.resolvedAt ? (
                        <Can permission="events:write">
                          <div className={styles.rowActions}>
                            <Button
                              type="button"
                              size="sm"
                              variant="outline"
                              isLoading={busyId === row.id}
                              onClick={() => void handleAction(row.id, 'resolve')}
                            >
                              {tRisk('resolve')}
                            </Button>
                            <Button
                              type="button"
                              size="sm"
                              variant="ghost"
                              disabled={busyId === row.id}
                              onClick={() => void handleAction(row.id, 'dismiss')}
                            >
                              {tRisk('dismiss')}
                            </Button>
                          </div>
                        </Can>
                      ) : (
                        <span className={styles.resolvedAt}>
                          {formatRiskSignalResolution(row, riskT) ?? formatEventDateTime(row.resolvedAt, locale)}
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
        <div className={styles.footer}>
          <p className={styles.meta}>
            {tRisk('signalsMeta', { count: initialResult.total, page: initialResult.page })}
          </p>
          {initialResult.total > initialResult.limit ? (
            <nav className={styles.riskSignalsPager} aria-label={tCommon('pagination')}>
              {initialResult.page > 1 ? (
                <Link className={styles.riskSignalsPagerLink} href={pageHref(initialResult.page - 1)}>
                  {tCommon('previousPage')}
                </Link>
              ) : (
                <span className={styles.riskSignalsPagerDisabled}>{tCommon('previousPage')}</span>
              )}
              <span className={styles.riskSignalsPagerMeta}>
                {initialResult.page} / {totalPages}
              </span>
              {initialResult.page < totalPages ? (
                <Link className={styles.riskSignalsPagerLink} href={pageHref(initialResult.page + 1)}>
                  {tCommon('nextPage')}
                </Link>
              ) : (
                <span className={styles.riskSignalsPagerDisabled}>{tCommon('nextPage')}</span>
              )}
            </nav>
          ) : null}
        </div>
      </div>
    </div>
  );
}
