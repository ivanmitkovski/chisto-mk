'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useCallback, useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Card, Drawer, MetadataView, PageHeader, Pagination, StickyTableWrap, useToast } from '@/components/ui';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import {
  WEBHOOK_LOG_ACTION_VALUES,
  webhookLogActionKey,
} from '../config/comms-filter-options';
import type { CommsListMeta, WebhookLogRow } from '../types';
import styles from './webhook-logs-workspace.module.css';

function formatAction(action: string): string {
  return action.replace(/_/g, ' ').toLowerCase().replace(/\b\w/g, (c) => c.toUpperCase());
}

type WebhookLogsWorkspaceProps = {
  initialData: WebhookLogRow[];
  initialMeta: CommsListMeta;
  initialAction: string;
};

export function WebhookLogsWorkspace({ initialData, initialMeta, initialAction }: WebhookLogsWorkspaceProps) {
  const t = useTranslations('comms.webhookLogs');
  const tCommon = useTranslations('common');
  const locale = useAdminBcp47Locale();
  const router = useRouter();
  const searchParams = useSearchParams();
  const { showToast } = useToast();
  const [data, setData] = useState(initialData);
  const [meta, setMeta] = useState(initialMeta);
  const [action, setAction] = useState(initialAction);
  const [payloadRow, setPayloadRow] = useState<WebhookLogRow | null>(null);

  useEffect(() => {
    setData(initialData);
    setMeta(initialMeta);
  }, [initialData, initialMeta]);

  useEffect(() => {
    setAction(initialAction);
  }, [initialAction]);

  const buildUrl = (updates: { page?: number; action?: string }) => {
    const sp = new URLSearchParams(searchParams.toString());
    if (updates.action !== undefined) {
      if (updates.action) sp.set('action', updates.action);
      else sp.delete('action');
    }
    if (updates.page !== undefined) {
      if (updates.page > 1) sp.set('page', String(updates.page));
      else sp.delete('page');
    }
    const q = sp.toString();
    return `/dashboard/comms/webhook-logs${q ? `?${q}` : ''}`;
  };

  const copyPayloadJson = useCallback(async () => {
    if (!payloadRow?.metadata) return;
    try {
      await navigator.clipboard.writeText(JSON.stringify(payloadRow.metadata, null, 2));
      showToast({ tone: 'success', title: tCommon('copied'), message: tCommon('payloadJsonCopied') });
    } catch {
      showToast({ tone: 'warning', title: tCommon('copyFailed'), message: tCommon('unableToCopyPayloadJson') });
    }
  }, [payloadRow, showToast, tCommon]);

  return (
    <div className={styles.layout}>
      <PageHeader title={t('pageTitle')} description={t('pageDescription')} />
      <Card padding="md">
        <div className={styles.toolbar}>
          <select
            className={styles.filterSelect}
            value={action}
            onChange={(e) => router.push(buildUrl({ action: e.target.value, page: 1 }))}
            aria-label={t('filterActionAria')}
          >
            {WEBHOOK_LOG_ACTION_VALUES.map((value) => (
              <option key={value || 'all-actions'} value={value}>
                {t(`actions.${webhookLogActionKey(value)}`)}
              </option>
            ))}
          </select>
          <Button variant="outline" size="sm" onClick={() => router.refresh()}>
            {tCommon('refresh')}
          </Button>
        </div>

        <StickyTableWrap className={styles.tableWrap}>
          {data.length === 0 ? (
            <div className={styles.empty}>{t('empty')}</div>
          ) : (
            <table className={styles.table}>
              <thead>
                <tr>
                  <th>{t('columns.when')}</th>
                  <th>{t('columns.action')}</th>
                  <th>{t('columns.resource')}</th>
                  <th>{t('columns.details')}</th>
                </tr>
              </thead>
              <tbody>
                {data.map((row) => (
                  <tr key={row.id}>
                    <td>{formatAdminDateTime(row.createdAt, locale)}</td>
                    <td className={styles.actionCell}>{formatAction(row.action)}</td>
                    <td>
                      {row.resourceType ?? '—'}
                      {row.resourceId ? ` · ${row.resourceId.slice(0, 8)}…` : ''}
                    </td>
                    <td className={styles.metaCell}>
                      {row.metadata && Object.keys(row.metadata).length > 0 ? (
                        <button
                          type="button"
                          className={styles.metaToggle}
                          onClick={() => setPayloadRow(row)}
                        >
                          {t('viewPayload')}
                        </button>
                      ) : (
                        '—'
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </StickyTableWrap>

        <div className={styles.footer}>
          <p className={styles.meta}>{t('meta', { count: meta.total, page: meta.page })}</p>
          {meta.total > meta.limit ? (
            <Pagination
              totalPages={Math.ceil(meta.total / meta.limit)}
              currentPage={meta.page}
              onPageChange={(p) => router.push(buildUrl({ page: p }))}
            />
          ) : null}
        </div>
      </Card>

      <Drawer
        open={payloadRow != null}
        title={t('payloadTitle')}
        onClose={() => setPayloadRow(null)}
      >
        {payloadRow?.metadata ? (
          <div className={styles.drawerContent}>
            <div className={styles.drawerActions}>
              <Button variant="outline" size="sm" onClick={() => void copyPayloadJson()}>
                {t('copyJson')}
              </Button>
            </div>
            <MetadataView value={payloadRow.metadata} />
          </div>
        ) : null}
      </Drawer>
    </div>
  );
}
