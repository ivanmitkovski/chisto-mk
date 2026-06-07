'use client';

import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { useState } from 'react';
import { motion, useReducedMotion } from 'framer-motion';
import { Button, Card, Checkbox, Icon, Pagination, SectionState } from '@/components/ui';
import { useServerSyncedState } from '@/features/admin-shell/hooks/use-server-synced-state';
import { Can } from '@/lib/auth/rbac';
import { DuplicateReportGroup, DuplicateReportItem } from '../types';
import { formatReportDate, statusIconName } from '../utils/report-status';
import { useFormatReportStatus } from '../hooks/use-format-report-status';
import { useDuplicates } from '../hooks/use-duplicates';
import { ActionConfirmModal } from './action-confirm-modal';
import styles from './duplicate-reports-workspace.module.css';

type DuplicateReportsWorkspaceProps = {
  initialGroups: DuplicateReportGroup[];
  initialMeta: { page: number; limit: number; total: number };
  initialSelectedGroupId?: string | null;
};

function statusPillClass(status: string): string {
  const map: Record<string, string> = {
    NEW: styles.statusNew,
    IN_REVIEW: styles.statusInReview,
    APPROVED: styles.statusApproved,
    DELETED: styles.statusDeleted,
  };
  return `${styles.statusPill} ${map[status] ?? styles.statusNew}`;
}

function ReportPreviewLink({ report, className }: { report: DuplicateReportItem; className?: string }) {
  return (
    <Link href={`/dashboard/reports/${report.id}`} className={className ?? styles.reportLink}>
      <strong>{report.reportNumber}</strong>
      <span>{report.title}</span>
    </Link>
  );
}

export function DuplicateReportsWorkspace({
  initialGroups,
  initialMeta,
  initialSelectedGroupId = null,
}: DuplicateReportsWorkspaceProps) {
  const t = useTranslations('reports.duplicates');
  const formatStatus = useFormatReportStatus();
  const tCommon = useTranslations('common');
  const router = useRouter();
  const searchParams = useSearchParams();
  const reduceMotion = useReducedMotion();
  const [groups, setGroups] = useServerSyncedState(initialGroups);
  const [meta] = useServerSyncedState(initialMeta);
  const {
    selectedGroupId,
    selectedGroup,
    selectedChildIds,
    isMerging,
    setSelectedGroupId,
    toggleChildSelection,
    selectAllChildren,
    mergeSelected,
  } = useDuplicates({
    groups,
    setGroups,
    initialSelectedGroupId,
    pagination: meta,
  });
  const [isMergeModalOpen, setIsMergeModalOpen] = useState(false);
  const [mergeReason, setMergeReason] = useState('');

  const buildUrl = (page: number) => {
    const sp = new URLSearchParams(searchParams.toString());
    const reportId = sp.get('reportId');
    if (page > 1) {
      sp.set('page', String(page));
    } else {
      sp.delete('page');
    }
    if (reportId) {
      sp.set('reportId', reportId);
    }
    const query = sp.toString();
    return `/dashboard/reports/duplicates${query ? `?${query}` : ''}`;
  };

  if (groups.length === 0) {
    return <SectionState variant="empty" message={t('empty')} />;
  }

  async function confirmMerge() {
    if (!selectedGroup) {
      return;
    }

    const didMerge = await mergeSelected(mergeReason);
    if (didMerge) {
      setIsMergeModalOpen(false);
      setMergeReason('');
      router.refresh();
    }
  }

  const allSelected = selectedGroup
    ? selectedGroup.duplicateReports.length > 0 &&
      selectedChildIds.length === selectedGroup.duplicateReports.length
    : false;

  const totalPages = Math.max(1, Math.ceil(meta.total / meta.limit));

  return (
    <>
      <div className={styles.layout}>
        <Card className={styles.groupsPanel}>
          <div className={styles.panelHeader}>
            <h2 className={styles.panelTitle}>{t('groupsTitle')}</h2>
            <span className={styles.panelBadge}>
              {t('groupsCount', { count: meta.total })}
            </span>
          </div>

          <div className={styles.groupsList}>
            {groups.map((group) => (
              <motion.button
                key={group.primaryReport.id}
                type="button"
                className={`${styles.groupButton} ${
                  selectedGroupId === group.primaryReport.id ? styles.groupButtonActive : ''
                }`}
                onClick={() => setSelectedGroupId(group.primaryReport.id)}
                transition={{ duration: reduceMotion ? 0 : 0.15 }}
                {...(!reduceMotion
                  ? { whileHover: { y: -1 }, whileTap: { scale: 0.995 } }
                  : {})}
              >
                <span className={styles.groupButtonTop}>
                  <Link
                    href={`/dashboard/reports/${group.primaryReport.id}`}
                    className={styles.groupReportLink}
                    onClick={(event) => event.stopPropagation()}
                  >
                    {group.primaryReport.reportNumber}
                  </Link>
                  <span className={styles.groupCount}>{group.totalReports}</span>
                </span>
                <span className={styles.groupTitle}>{group.primaryReport.title}</span>
                <span className={styles.groupMeta}>
                  <Icon name="location" size={12} aria-hidden />
                  {group.primaryReport.location}
                </span>
                <span className={statusPillClass(group.primaryReport.status)}>
                  <Icon name={statusIconName(group.primaryReport.status)} size={10} aria-hidden />
                  {formatStatus(group.primaryReport.status)}
                </span>
              </motion.button>
            ))}
          </div>

          {meta.total > meta.limit ? (
            <div className={styles.paginationWrap}>
              <Pagination
                totalPages={totalPages}
                currentPage={meta.page}
                onPageChange={(page) => router.push(buildUrl(page))}
              />
            </div>
          ) : null}
        </Card>

        <Card className={styles.detailPanel}>
          {!selectedGroup ? (
            <SectionState variant="empty" message={t('selectGroupEmpty')} />
          ) : (
            <>
              <div className={styles.panelHeader}>
                <h2 className={styles.panelTitle}>{t('mergeWorkspaceTitle')}</h2>
                <p className={styles.panelSubtitle}>
                  {t('mergeWorkspaceSubtitle', {
                    reportNumber: selectedGroup.primaryReport.reportNumber,
                    count: selectedGroup.totalReports,
                  })}
                </p>
              </div>

              <section className={styles.primarySection}>
                <span className={styles.sectionLabel}>{t('primaryReport')}</span>
                <motion.article
                  className={styles.primaryCard}
                  initial={reduceMotion ? false : { opacity: 0, y: 4 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: reduceMotion ? 0 : 0.2 }}
                >
                  <div className={styles.primaryCardHeader}>
                    <p className={styles.primaryTitle}>{selectedGroup.primaryReport.title}</p>
                    <Link
                      href={`/dashboard/reports/${selectedGroup.primaryReport.id}`}
                      className={styles.viewReportLink}
                    >
                      {t('viewReport')}
                      <Icon name="chevron-right" size={12} aria-hidden />
                    </Link>
                  </div>
                  <p className={styles.metaLine}>
                    <Icon name="location" size={14} aria-hidden />
                    {selectedGroup.primaryReport.location}
                  </p>
                  <div className={styles.primaryMeta}>
                    <span className={statusPillClass(selectedGroup.primaryReport.status)}>
                      <Icon name={statusIconName(selectedGroup.primaryReport.status)} size={10} aria-hidden />
                      {formatStatus(selectedGroup.primaryReport.status)}
                    </span>
                    <span className={styles.primaryDate}>
                      {formatReportDate(selectedGroup.primaryReport.submittedAt)}
                    </span>
                  </div>
                </motion.article>
              </section>

              <section className={styles.duplicatesSection}>
                <div className={styles.duplicatesHeader}>
                  <span className={styles.sectionLabel}>
                    {t('duplicatesToMerge', { count: selectedGroup.duplicateReports.length })}
                  </span>
                  <button
                    type="button"
                    className={styles.selectAllBtn}
                    onClick={selectAllChildren}
                    aria-pressed={allSelected}
                    aria-label={allSelected ? tCommon('deselectAll') : tCommon('selectAll')}
                  >
                    {allSelected ? tCommon('deselectAll') : tCommon('selectAll')}
                  </button>
                </div>

                <ul className={styles.duplicatesList}>
                  {selectedGroup.duplicateReports.map((child, i) => (
                    <motion.li
                      key={child.id}
                      className={styles.duplicateRow}
                      initial={reduceMotion ? false : { opacity: 0, y: 4 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{
                        duration: reduceMotion ? 0 : 0.2,
                        delay: reduceMotion ? 0 : i * 0.03,
                      }}
                    >
                      <Checkbox
                        className={styles.duplicateRowCheckbox}
                        labelAlign="start"
                        checked={selectedChildIds.includes(child.id)}
                        onChange={() => toggleChildSelection(child.id)}
                        aria-label={t('selectDuplicateAria', { reportNumber: child.reportNumber })}
                        label={
                          <span className={styles.duplicateContent}>
                            <ReportPreviewLink report={child} />
                          </span>
                        }
                      />
                      <div className={styles.duplicateMeta}>
                        <span className={statusPillClass(child.status)}>
                          <Icon name={statusIconName(child.status)} size={10} aria-hidden />
                          {formatStatus(child.status)}
                        </span>
                        <span>{formatReportDate(child.submittedAt)}</span>
                        <span>{t('mediaCount', { count: child.mediaCount })}</span>
                        <Link href={`/dashboard/reports/${child.id}`} className={styles.childPreviewLink}>
                          {tCommon('preview')}
                        </Link>
                      </div>
                    </motion.li>
                  ))}
                </ul>
              </section>

              <div className={styles.actions}>
                <span className={styles.selectionHint}>
                  {t('selectionHint', {
                    count: selectedChildIds.length,
                    total: selectedGroup.duplicateReports.length,
                  })}
                </span>
                <Can permission="reports:merge">
                  <Button
                    onClick={() => setIsMergeModalOpen(true)}
                    isLoading={isMerging}
                    disabled={selectedChildIds.length === 0}
                  >
                    <Icon name="check" size={14} aria-hidden />
                    {t('approveAndMerge')}
                  </Button>
                </Can>
              </div>
            </>
          )}
        </Card>
      </div>

      <ActionConfirmModal
        isOpen={isMergeModalOpen}
        title={t('confirmMergeTitle')}
        description={t('confirmMergeDescription')}
        confirmLabel={t('approveAndMerge')}
        notesLabel={t('mergeReasonLabel')}
        notesPlaceholder={t('mergeReasonPlaceholder')}
        cancelLabel={tCommon('cancel')}
        notesValue={mergeReason}
        onNotesChange={setMergeReason}
        isConfirming={isMerging}
        onCancel={() => {
          if (isMerging) {
            return;
          }
          setIsMergeModalOpen(false);
        }}
        onConfirm={confirmMerge}
      />
    </>
  );
}
