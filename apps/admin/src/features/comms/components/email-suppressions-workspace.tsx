'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { FormEvent, useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Card, ConfirmDialog, Input, PageHeader, Pagination, StickyTableWrap, useToast } from '@/components/ui';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import { Can } from '@/lib/auth/rbac';
import { adminBrowserFetch } from '@/lib/api';
import {
  EMAIL_SUPPRESSION_REASON_VALUES,
  EMAIL_SUPPRESSION_SOURCE_VALUES,
  emailSuppressionReasonKey,
  emailSuppressionSourceKey,
} from '../config/comms-filter-options';
import type { CommsListMeta, EmailSuppressionRow } from '../types';
import styles from './email-suppressions-workspace.module.css';

type EmailSuppressionsWorkspaceProps = {
  initialData: EmailSuppressionRow[];
  initialMeta: CommsListMeta;
  initialSearch: string;
  initialReason: string;
  initialSource: string;
};

export function EmailSuppressionsWorkspace({
  initialData,
  initialMeta,
  initialSearch,
  initialReason,
  initialSource,
}: EmailSuppressionsWorkspaceProps) {
  const t = useTranslations('comms.emailSuppressions');
  const tCommon = useTranslations('common');
  const locale = useAdminBcp47Locale();
  const router = useRouter();
  const searchParams = useSearchParams();
  const [data, setData] = useState(initialData);
  const [meta, setMeta] = useState(initialMeta);
  const [search, setSearch] = useState(initialSearch);
  const [reason, setReason] = useState(initialReason);
  const [source, setSource] = useState(initialSource);
  const [busyEmail, setBusyEmail] = useState<string | null>(null);
  const [removeTarget, setRemoveTarget] = useState<string | null>(null);
  const [createOpen, setCreateOpen] = useState(false);
  const [createEmail, setCreateEmail] = useState('');
  const [createEmailError, setCreateEmailError] = useState<string | null>(null);
  const [createBusy, setCreateBusy] = useState(false);
  const { showToast } = useToast();

  function formatReasonLabel(value: string): string {
    const key = emailSuppressionReasonKey(
      EMAIL_SUPPRESSION_REASON_VALUES.includes(value as (typeof EMAIL_SUPPRESSION_REASON_VALUES)[number])
        ? (value as (typeof EMAIL_SUPPRESSION_REASON_VALUES)[number])
        : '',
    );
    return key === 'all' ? value : t(`reasons.${key}`);
  }

  function formatSourceLabel(value: string): string {
    const key = emailSuppressionSourceKey(
      EMAIL_SUPPRESSION_SOURCE_VALUES.includes(value as (typeof EMAIL_SUPPRESSION_SOURCE_VALUES)[number])
        ? (value as (typeof EMAIL_SUPPRESSION_SOURCE_VALUES)[number])
        : '',
    );
    return key === 'all' ? value : t(`sources.${key}`);
  }

  useEffect(() => {
    setData(initialData);
    setMeta(initialMeta);
  }, [initialData, initialMeta]);

  useEffect(() => {
    setSearch(initialSearch);
  }, [initialSearch]);

  useEffect(() => {
    setReason(initialReason);
  }, [initialReason]);

  useEffect(() => {
    setSource(initialSource);
  }, [initialSource]);

  const buildUrl = (updates: { search?: string; reason?: string; source?: string; page?: number }) => {
    const sp = new URLSearchParams(searchParams.toString());
    if (updates.search !== undefined) {
      if (updates.search) sp.set('search', updates.search);
      else sp.delete('search');
    }
    if (updates.reason !== undefined) {
      if (updates.reason) sp.set('reason', updates.reason);
      else sp.delete('reason');
    }
    if (updates.source !== undefined) {
      if (updates.source) sp.set('source', updates.source);
      else sp.delete('source');
    }
    if (updates.page !== undefined) {
      if (updates.page > 1) sp.set('page', String(updates.page));
      else sp.delete('page');
    }
    const q = sp.toString();
    return `/dashboard/comms/email-suppressions${q ? `?${q}` : ''}`;
  };

  function onSearchSubmit(e: FormEvent) {
    e.preventDefault();
    router.push(buildUrl({ search, reason, source, page: 1 }));
  }

  function onFilterChange(next: { reason?: string; source?: string }) {
    router.push(
      buildUrl({
        search,
        reason: next.reason ?? reason,
        source: next.source ?? source,
        page: 1,
      }),
    );
  }

  async function submitCreateSuppression() {
    const email = createEmail.trim().toLowerCase();
    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      setCreateEmailError(t('create.invalidEmail'));
      return;
    }
    setCreateEmailError(null);
    setCreateBusy(true);
    try {
      const created = await adminBrowserFetch<EmailSuppressionRow>('/admin/comms/email-suppressions', {
        method: 'POST',
        body: { email, reason: 'ManualSuppression' },
      });
      setData((current) => [created, ...current.filter((row) => row.email !== created.email)]);
      setMeta((current) => ({ ...current, total: current.total + 1 }));
      showToast({
        tone: 'success',
        title: t('toast.createdTitle'),
        message: t('toast.createdMessage', { email: created.email }),
      });
      setCreateOpen(false);
      setCreateEmail('');
    } catch (error) {
      showToast({
        tone: 'warning',
        title: t('toast.createFailedTitle'),
        message: error instanceof Error ? error.message : t('toast.createFailedMessage'),
      });
    } finally {
      setCreateBusy(false);
    }
  }

  async function removeSuppression(email: string) {
    const previousData = data;
    const previousMeta = meta;
    setBusyEmail(email);
    setData((current) => current.filter((row) => row.email !== email));
    setMeta((current) => ({ ...current, total: Math.max(0, current.total - 1) }));
    try {
      await adminBrowserFetch(`/admin/comms/email-suppressions/${encodeURIComponent(email)}`, {
        method: 'DELETE',
      });
      showToast({
        tone: 'success',
        title: t('toast.removedTitle'),
        message: t('toast.removedMessage', { email }),
      });
      setRemoveTarget(null);
    } catch (error) {
      setData(previousData);
      setMeta(previousMeta);
      showToast({
        tone: 'warning',
        title: t('toast.removeFailedTitle'),
        message: error instanceof Error ? error.message : t('toast.removeFailedMessage'),
      });
    } finally {
      setBusyEmail(null);
    }
  }

  return (
    <div className={styles.layout}>
      <PageHeader title={t('pageTitle')} description={t('pageDescription')} />
      <Card padding="md">
        <div className={styles.toolbar}>
          <form className={styles.searchForm} onSubmit={onSearchSubmit}>
            <Input
              type="search"
              placeholder={t('searchPlaceholder')}
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className={styles.searchInput}
              aria-label={t('searchAria')}
            />
            <select
              className={styles.filterSelect}
              value={reason}
              onChange={(e) => onFilterChange({ reason: e.target.value })}
              aria-label={t('filterReasonAria')}
            >
              {EMAIL_SUPPRESSION_REASON_VALUES.map((value) => (
                <option key={value || 'all-reasons'} value={value}>
                  {t(`reasons.${emailSuppressionReasonKey(value)}`)}
                </option>
              ))}
            </select>
            <select
              className={styles.filterSelect}
              value={source}
              onChange={(e) => onFilterChange({ source: e.target.value })}
              aria-label={t('filterSourceAria')}
            >
              {EMAIL_SUPPRESSION_SOURCE_VALUES.map((value) => (
                <option key={value || 'all-sources'} value={value}>
                  {t(`sources.${emailSuppressionSourceKey(value)}`)}
                </option>
              ))}
            </select>
            <Button type="submit" variant="outline" size="sm">
              {tCommon('search')}
            </Button>
          </form>
          <Button variant="outline" size="sm" onClick={() => router.refresh()}>
            {tCommon('refresh')}
          </Button>
          <Can permission="comms:write">
            <Button size="sm" onClick={() => setCreateOpen(true)}>
              {t('create.button')}
            </Button>
          </Can>
        </div>

        <StickyTableWrap className={styles.tableWrap}>
          {data.length === 0 ? (
            <div className={styles.empty}>{t('empty')}</div>
          ) : (
            <table className={styles.table}>
              <thead>
                <tr>
                  <th>{t('columns.email')}</th>
                  <th>{t('columns.reason')}</th>
                  <th>{t('columns.source')}</th>
                  <th>{t('columns.created')}</th>
                  <th className={styles.thActions}>{t('columns.actions')}</th>
                </tr>
              </thead>
              <tbody>
                {data.map((row) => (
                  <tr key={row.email}>
                    <td className={styles.emailCell}>{row.email}</td>
                    <td>
                      <span className={styles.reasonPill}>{formatReasonLabel(row.reason)}</span>
                    </td>
                    <td>{formatSourceLabel(row.source)}</td>
                    <td>{formatAdminDateTime(row.createdAt, locale)}</td>
                    <td className={styles.tdActions}>
                      <Can permission="comms:write">
                        <Button
                          variant="outline"
                          size="sm"
                          disabled={busyEmail === row.email}
                          onClick={() => setRemoveTarget(row.email)}
                        >
                          {busyEmail === row.email ? t('removing') : t('remove')}
                        </Button>
                      </Can>
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
      <ConfirmDialog
        open={createOpen}
        title={t('create.title')}
        description={t('create.description')}
        confirmLabel={t('create.submit')}
        isLoading={createBusy}
        onConfirm={() => void submitCreateSuppression()}
        onClose={() => {
          if (createBusy) return;
          setCreateOpen(false);
          setCreateEmail('');
          setCreateEmailError(null);
        }}
      >
        <Input
          label={t('columns.email')}
          type="email"
          value={createEmail}
          errorText={createEmailError ?? undefined}
          onChange={(event) => {
            setCreateEmail(event.target.value);
            if (createEmailError) setCreateEmailError(null);
          }}
        />
      </ConfirmDialog>
      <ConfirmDialog
        open={removeTarget != null}
        title={t('confirmRemoveTitle')}
        tone="danger"
        description={removeTarget ? t('confirmRemoveDescription', { email: removeTarget }) : ''}
        confirmLabel={t('remove')}
        isLoading={busyEmail != null}
        onConfirm={() => {
          if (removeTarget) void removeSuppression(removeTarget);
        }}
        onClose={() => setRemoveTarget(null)}
      />
    </div>
  );
}
