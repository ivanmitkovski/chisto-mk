'use client';

import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { FormEvent, useEffect, useMemo, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Badge, Button, Card, ConfirmDialog, Field, Input, Modal, Pagination, SectionState, useToast } from '@/components/ui';
import { useServerSyncedState } from '@/features/admin-shell/hooks/use-server-synced-state';
import { Can } from '@/lib/auth/rbac';
import { useReadOnlyUnless } from '@/lib/auth/rbac/use-read-only-unless';
import { adminBrowserFetch } from '@/lib/api';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import type { UgcModerationReport } from '../data/ugc-moderation-adapter';
import {
  formatUgcSubjectType,
  formatUgcLabel,
  getUgcModerationActions,
  getUgcStatusFilterOptions,
  getUgcSubjectTypeFilterOptions,
  getUgcSubjectDashboardHref,
  getUgcSubjectPreviewLabel,
  isUgcActionAllowed,
  ugcActionRequiresPolicyReason,
  ugcBadgeTone,
  type UgcModerationAction,
} from '../lib/ugc-moderation-utils';
import { useUgcStatusLabel } from '../hooks/use-ugc-status-label';
import styles from './ugc-moderation-workspace.module.css';

type UgcModerationWorkspaceProps = {
  initialReports: UgcModerationReport[];
  initialMeta: { page: number; limit: number; total: number };
  initialSelectedReportId?: string | null;
  initialStatusFilter?: string;
  initialSubjectTypeFilter?: string;
  initialSearch?: string;
};

export function UgcModerationWorkspace({
  initialReports,
  initialMeta,
  initialSelectedReportId = null,
  initialStatusFilter = '',
  initialSubjectTypeFilter = '',
  initialSearch = '',
}: UgcModerationWorkspaceProps) {
  const t = useTranslations('moderation');
  const tCommon = useTranslations('common');
  const locale = useAdminBcp47Locale();
  const router = useRouter();
  const searchParams = useSearchParams();
  const readOnly = useReadOnlyUnless('moderation:write');
  const [reports, setReports] = useServerSyncedState(initialReports);
  const [meta] = useServerSyncedState(initialMeta);
  const [searchDraft, setSearchDraft] = useState(initialSearch);
  const moderationActions = useMemo(() => getUgcModerationActions(t), [t]);
  const statusFilterOptions = useMemo(() => getUgcStatusFilterOptions(t), [t]);
  const subjectTypeFilterOptions = useMemo(() => getUgcSubjectTypeFilterOptions(t), [t]);
  const formatStatus = useUgcStatusLabel();
  const defaultSelectedReportId =
    initialSelectedReportId && reports.some((report) => report.id === initialSelectedReportId)
      ? initialSelectedReportId
      : reports[0]?.id ?? null;
  const [selectedReportId, setSelectedReportId] = useState<string | null>(defaultSelectedReportId);
  const [pendingAction, setPendingAction] = useState<UgcModerationAction | null>(null);
  const [note, setNote] = useState('');
  const [policyReason, setPolicyReason] = useState('');
  const [policyReasonError, setPolicyReasonError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const { showToast } = useToast();

  useEffect(() => {
    setSearchDraft(initialSearch);
  }, [initialSearch]);

  useEffect(() => {
    if (initialSelectedReportId && reports.some((report) => report.id === initialSelectedReportId)) {
      setSelectedReportId(initialSelectedReportId);
      return;
    }
    if (selectedReportId && reports.some((report) => report.id === selectedReportId)) {
      return;
    }
    setSelectedReportId(reports[0]?.id ?? null);
  }, [initialSelectedReportId, reports, selectedReportId]);

  const selectedReport = useMemo(
    () => reports.find((report) => report.id === selectedReportId) ?? null,
    [reports, selectedReportId],
  );

  const openCount = useMemo(() => reports.filter((report) => report.status === 'OPEN').length, [reports]);

  const buildUrl = (updates: {
    page?: number;
    status?: string;
    subjectType?: string;
    search?: string;
    reportId?: string | null;
  }) => {
    const sp = new URLSearchParams(searchParams.toString());
    if (updates.status !== undefined) {
      if (updates.status) sp.set('status', updates.status);
      else sp.delete('status');
    }
    if (updates.subjectType !== undefined) {
      if (updates.subjectType) sp.set('subjectType', updates.subjectType);
      else sp.delete('subjectType');
    }
    if (updates.search !== undefined) {
      if (updates.search.trim()) sp.set('search', updates.search.trim());
      else sp.delete('search');
    }
    if (updates.page !== undefined) {
      if (updates.page > 1) sp.set('page', String(updates.page));
      else sp.delete('page');
    }
    if (updates.reportId !== undefined) {
      if (updates.reportId) sp.set('reportId', updates.reportId);
      else sp.delete('reportId');
    }
    const query = sp.toString();
    return `/dashboard/moderation/ugc${query ? `?${query}` : ''}`;
  };

  function selectReport(report: UgcModerationReport) {
    setSelectedReportId(report.id);
    router.replace(buildUrl({ reportId: report.id }), { scroll: false });
  }

  function validatePolicyReason(action: UgcModerationAction): boolean {
    if (!ugcActionRequiresPolicyReason(action)) {
      setPolicyReasonError(null);
      return true;
    }
    if (!policyReason.trim()) {
      setPolicyReasonError(t('modal.policyReasonRequired'));
      return false;
    }
    setPolicyReasonError(null);
    return true;
  }

  async function submitAction() {
    if (!selectedReport || !pendingAction) return;
    if (!validatePolicyReason(pendingAction)) {
      return;
    }

    setBusy(true);
    try {
      const updated = await adminBrowserFetch<UgcModerationReport>(
        `/admin/moderation/ugc-reports/${encodeURIComponent(selectedReport.id)}`,
        {
          method: 'PATCH',
          body: {
            action: pendingAction,
            note: note.trim() || undefined,
            policyReason: policyReason.trim() || undefined,
          },
        },
      );
      setReports((current) => current.map((report) => (report.id === updated.id ? updated : report)));
      setSelectedReportId(updated.id);
      setPendingAction(null);
      setNote('');
      setPolicyReason('');
      setPolicyReasonError(null);
      showToast({ tone: 'success', title: t('toast.savedTitle'), message: t('toast.savedMessage') });
      router.refresh();
    } catch (error) {
      showToast({
        tone: 'warning',
        title: t('toast.failedTitle'),
        message: error instanceof Error ? error.message : t('toast.failedMessage'),
      });
    } finally {
      setBusy(false);
    }
  }

  function onSearchSubmit(event: FormEvent) {
    event.preventDefault();
    router.push(buildUrl({ search: searchDraft, page: 1 }));
  }

  if (reports.length === 0) {
    const hasFilters = Boolean(initialStatusFilter || initialSubjectTypeFilter || initialSearch.trim());
    return (
      <SectionState
        variant="empty"
        message={hasFilters && meta.total === 0 ? t('emptyFiltered') : t('empty')}
      />
    );
  }

  const subjectHref = selectedReport
    ? getUgcSubjectDashboardHref(selectedReport.subjectType, selectedReport.subjectId)
    : null;

  const pendingActionLabel =
    pendingAction != null
      ? moderationActions.find((action) => action.id === pendingAction)?.label ?? t('actions.moderateReport')
      : t('actions.moderateReport');

  const pendingActionRequiresPolicyReason =
    pendingAction != null && ugcActionRequiresPolicyReason(pendingAction);
  const pendingActionIsDanger = pendingAction === 'hide_subject';

  return (
    <div className={styles.layout}>
      {readOnly ? (
        <div className={styles.readOnlyBanner} role="status">
          {t('readOnlyBanner')}
        </div>
      ) : null}
      <aside className={styles.queue} aria-label={t('queueAria')}>
        <div className={styles.queueHeader}>
          <div>
            <strong>{t('reportsCount', { total: meta.total })}</strong>
            <span>{t('openOnPage', { count: openCount })}</span>
          </div>
          <Button type="button" variant="outline" size="sm" onClick={() => router.refresh()}>
            {tCommon('refresh')}
          </Button>
        </div>

        <div className={styles.filters}>
          <form className={styles.searchForm} onSubmit={onSearchSubmit}>
            <Input
              type="search"
              placeholder={t('searchPlaceholder')}
              value={searchDraft}
              onChange={(event) => setSearchDraft(event.target.value)}
              aria-label={t('searchAria')}
            />
            <Button type="submit" variant="outline" size="sm">
              {tCommon('search')}
            </Button>
          </form>
          <label className={styles.filterLabel} htmlFor="ugc-status-filter">
            {t('statusFilter')}
          </label>
          <select
            id="ugc-status-filter"
            className={styles.filterSelect}
            value={initialStatusFilter}
            onChange={(event) => router.push(buildUrl({ status: event.target.value, page: 1 }))}
          >
            {statusFilterOptions.map((option) => (
              <option key={option.value || 'all'} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
          <label className={styles.filterLabel} htmlFor="ugc-subject-type-filter">
            {t('subjectTypeFilter')}
          </label>
          <select
            id="ugc-subject-type-filter"
            className={styles.filterSelect}
            value={initialSubjectTypeFilter}
            onChange={(event) => router.push(buildUrl({ subjectType: event.target.value, page: 1 }))}
          >
            {subjectTypeFilterOptions.map((option) => (
              <option key={option.value || 'all-subjects'} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </div>

        {reports.map((report) => (
          <button
            key={report.id}
            type="button"
            className={
              report.id === selectedReportId ? `${styles.queueItem} ${styles.queueItemActive}` : styles.queueItem
            }
            aria-current={report.id === selectedReportId ? 'true' : undefined}
            onClick={() => selectReport(report)}
          >
            <span>{formatUgcSubjectType(report.subjectType, t)}</span>
            <Badge tone={ugcBadgeTone(report.status)}>{formatStatus(report.status)}</Badge>
            <small>{formatUgcLabel(report.reason)}</small>
          </button>
        ))}

        {meta.total > meta.limit ? (
          <div className={styles.paginationWrap}>
            <Pagination
              totalPages={Math.ceil(meta.total / meta.limit)}
              currentPage={meta.page}
              onPageChange={(page) => router.push(buildUrl({ page }))}
            />
          </div>
        ) : null}
      </aside>

      {selectedReport ? (
        <Card padding="md" className={styles.detail}>
          <div className={styles.detailHeader}>
            <div>
              <p className={styles.kicker}>{t('detail.kicker')}</p>
              <h2>{formatUgcSubjectType(selectedReport.subjectType, t)}</h2>
            </div>
            <Badge tone={ugcBadgeTone(selectedReport.status)}>{formatStatus(selectedReport.status)}</Badge>
          </div>

          <section className={styles.subjectPreview}>
            <h3>{t('detail.subjectPreview')}</h3>
            <p className={styles.subjectPreviewType}>
              {getUgcSubjectPreviewLabel(selectedReport.subjectType, t)}
            </p>
            <p className={styles.subjectPreviewId}>
              ID <code>{selectedReport.subjectId}</code>
            </p>
            {subjectHref ? (
              <Link href={subjectHref} className={styles.subjectLink}>
                {t('detail.openRecord', { subjectType: formatUgcSubjectType(selectedReport.subjectType, t) })}
              </Link>
            ) : (
              <p className={styles.subjectPreviewHint}>{t('detail.noDetailPage')}</p>
            )}
          </section>

          <dl className={styles.metaGrid}>
            <div>
              <dt>{t('detail.caseStatus')}</dt>
              <dd>{selectedReport.caseStatus ?? '—'}</dd>
            </div>
            <div>
              <dt>{t('detail.contentStatus')}</dt>
              <dd>{selectedReport.contentStatus ?? '—'}</dd>
            </div>
          </dl>

          <dl className={styles.metaGrid}>
            <div>
              <dt>{t('detail.reason')}</dt>
              <dd>{formatUgcLabel(selectedReport.reason)}</dd>
            </div>
            <div>
              <dt>{t('detail.reporter')}</dt>
              <dd>
                {selectedReport.reporterName || tCommon('unknown')}
                {selectedReport.reporterEmail ? <span>{selectedReport.reporterEmail}</span> : null}
              </dd>
            </div>
            <div>
              <dt>{t('detail.created')}</dt>
              <dd>{formatAdminDateTime(selectedReport.createdAt, locale)}</dd>
            </div>
            <div>
              <dt>{t('detail.reporterProfile')}</dt>
              <dd>
                <Link href={`/dashboard/users/${selectedReport.reporterId}`} className={styles.subjectLink}>
                  {t('detail.viewReporter')}
                </Link>
              </dd>
            </div>
          </dl>

          {selectedReport.details ? (
            <section className={styles.detailsBox}>
              <h3>{t('detail.reporterDetails')}</h3>
              <p>{selectedReport.details}</p>
            </section>
          ) : null}

          <div className={styles.actions}>
            {moderationActions.map((action) => {
              const allowed = isUgcActionAllowed(action.id, selectedReport.status);
              return (
                <Can key={action.id} permission="moderation:write">
                  <Button
                    type="button"
                    variant={action.tone === 'neutral' ? 'outline' : 'solid'}
                    disabled={readOnly || !allowed}
                    title={allowed ? undefined : t('detail.actionUnavailable')}
                    onClick={() => {
                      setPolicyReasonError(null);
                      setPendingAction(action.id);
                    }}
                  >
                    {action.label}
                  </Button>
                </Can>
              );
            })}
          </div>
        </Card>
      ) : null}

      {pendingAction != null && pendingActionIsDanger ? (
        <ConfirmDialog
          open
          tone="danger"
          title={t('modal.hideSubjectConfirmTitle')}
          description={t('modal.hideSubjectConfirmDescription')}
          confirmLabel={t('actions.hideSubject')}
          isLoading={busy}
          onConfirm={() => {
            if (pendingAction && validatePolicyReason(pendingAction)) {
              void submitAction();
            }
          }}
          onClose={() => {
            if (busy) return;
            setPendingAction(null);
            setPolicyReasonError(null);
          }}
        >
          {pendingActionRequiresPolicyReason ? (
            <Field
              label={t('modal.policyReasonLabel')}
              htmlFor="ugc-policy-reason-danger"
              errorText={policyReasonError ?? undefined}
            >
              <Input
                id="ugc-policy-reason-danger"
                value={policyReason}
                onChange={(event) => {
                  setPolicyReason(event.target.value);
                  if (policyReasonError && event.target.value.trim()) {
                    setPolicyReasonError(null);
                  }
                }}
                maxLength={200}
                aria-invalid={policyReasonError != null}
              />
            </Field>
          ) : null}
          <Field label={t('modal.moderatorNoteLabel')} htmlFor="ugc-moderator-note-danger" className={styles.noteField}>
            <textarea
              id="ugc-moderator-note-danger"
              value={note}
              onChange={(event) => setNote(event.target.value)}
              maxLength={1000}
            />
          </Field>
        </ConfirmDialog>
      ) : null}

      <Modal
        open={pendingAction != null && !pendingActionIsDanger}
        title={pendingActionLabel}
        description={t('modal.description')}
        onClose={() => {
          if (busy) return;
          setPendingAction(null);
          setPolicyReasonError(null);
        }}
        footer={
          <>
            <Button
              type="button"
              variant="outline"
              onClick={() => {
                setPendingAction(null);
                setPolicyReasonError(null);
              }}
              disabled={busy}
            >
              {tCommon('cancel')}
            </Button>
            <Button
              type="button"
              onClick={() => {
                if (pendingAction && validatePolicyReason(pendingAction)) {
                  void submitAction();
                }
              }}
              isLoading={busy}
            >
              {tCommon('confirm')}
            </Button>
          </>
        }
      >
        {pendingActionRequiresPolicyReason ? (
          <Field
            label={t('modal.policyReasonLabel')}
            htmlFor="ugc-policy-reason"
            errorText={policyReasonError ?? undefined}
          >
            <Input
              id="ugc-policy-reason"
              value={policyReason}
              onChange={(event) => {
                setPolicyReason(event.target.value);
                if (policyReasonError && event.target.value.trim()) {
                  setPolicyReasonError(null);
                }
              }}
              maxLength={200}
              aria-invalid={policyReasonError != null}
            />
          </Field>
        ) : null}
        <Field label={t('modal.moderatorNoteLabel')} htmlFor="ugc-moderator-note" className={styles.noteField}>
          <textarea
            id="ugc-moderator-note"
            value={note}
            onChange={(event) => setNote(event.target.value)}
            maxLength={1000}
          />
        </Field>
      </Modal>
    </div>
  );
}
