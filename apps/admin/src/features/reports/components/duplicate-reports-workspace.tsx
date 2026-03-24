'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { motion, useReducedMotion } from 'framer-motion';
import { Button, Card, Icon, SectionState, Snack } from '@/components/ui';
import { DuplicateReportGroup } from '../types';
import { formatReportDate, formatReportStatus, statusIconName } from '../utils/report-status';
import { useDuplicates } from '../hooks/use-duplicates';
import { ActionConfirmModal } from './action-confirm-modal';
import styles from './duplicate-reports-workspace.module.css';

type DuplicateReportsWorkspaceProps = {
  initialGroups: DuplicateReportGroup[];
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

export function DuplicateReportsWorkspace({
  initialGroups,
  initialSelectedGroupId = null,
}: DuplicateReportsWorkspaceProps) {
  const router = useRouter();
  const reduceMotion = useReducedMotion();
  const {
    groups,
    selectedGroupId,
    selectedGroup,
    selectedChildIds,
    isMerging,
    snack,
    setSelectedGroupId,
    toggleChildSelection,
    selectAllChildren,
    mergeSelected,
    clearSnack,
  } = useDuplicates({ initialGroups, initialSelectedGroupId });
  const [isMergeModalOpen, setIsMergeModalOpen] = useState(false);
  const [mergeReason, setMergeReason] = useState('');

  if (groups.length === 0) {
    return <SectionState variant="empty" message="No duplicate report groups are currently waiting for moderation." />;
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

  return (
    <>
      <div className={styles.layout}>
        <Card className={styles.groupsPanel}>
          <div className={styles.panelHeader}>
            <h2 className={styles.panelTitle}>Duplicate groups</h2>
            <span className={styles.panelBadge}>{groups.length} group{groups.length !== 1 ? 's' : ''}</span>
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
                  <strong className={styles.groupReportNum}>{group.primaryReport.reportNumber}</strong>
                  <span className={styles.groupCount}>{group.totalReports}</span>
                </span>
                <span className={styles.groupTitle}>{group.primaryReport.title}</span>
                <span className={styles.groupMeta}>
                  <Icon name="location" size={12} aria-hidden />
                  {group.primaryReport.location}
                </span>
                <span className={statusPillClass(group.primaryReport.status)}>
                  <Icon name={statusIconName(group.primaryReport.status)} size={10} aria-hidden />
                  {formatReportStatus(group.primaryReport.status)}
                </span>
              </motion.button>
            ))}
          </div>
        </Card>

        <Card className={styles.detailPanel}>
          {!selectedGroup ? (
            <SectionState variant="empty" message="Select a duplicate group to review and merge." />
          ) : (
            <>
              <div className={styles.panelHeader}>
                <h2 className={styles.panelTitle}>Merge workspace</h2>
                <p className={styles.panelSubtitle}>
                  Primary <strong>{selectedGroup.primaryReport.reportNumber}</strong> ·{' '}
                  {selectedGroup.totalReports} reports
                </p>
              </div>

              <section className={styles.primarySection}>
                <span className={styles.sectionLabel}>Primary report</span>
                <motion.article
                  className={styles.primaryCard}
                  initial={reduceMotion ? false : { opacity: 0, y: 4 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: reduceMotion ? 0 : 0.2 }}
                >
                  <p className={styles.primaryTitle}>{selectedGroup.primaryReport.title}</p>
                  <p className={styles.metaLine}>
                    <Icon name="location" size={14} aria-hidden />
                    {selectedGroup.primaryReport.location}
                  </p>
                  <div className={styles.primaryMeta}>
                    <span className={statusPillClass(selectedGroup.primaryReport.status)}>
                      <Icon name={statusIconName(selectedGroup.primaryReport.status)} size={10} aria-hidden />
                      {formatReportStatus(selectedGroup.primaryReport.status)}
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
                    Duplicates to merge ({selectedGroup.duplicateReports.length})
                  </span>
                  <button
                    type="button"
                    className={styles.selectAllBtn}
                    onClick={selectAllChildren}
                    aria-pressed={allSelected}
                    aria-label={allSelected ? 'Deselect all duplicates' : 'Select all duplicates'}
                  >
                    {allSelected ? 'Deselect all' : 'Select all'}
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
                      <label className={styles.checkboxLabel}>
                        <span className={styles.checkboxWrap}>
                          <input
                            type="checkbox"
                            checked={selectedChildIds.includes(child.id)}
                            onChange={() => toggleChildSelection(child.id)}
                            className={styles.checkboxInput}
                          />
                          <span className={styles.checkboxBox}>
                            <Icon name="check" size={12} aria-hidden />
                          </span>
                        </span>
                        <span className={styles.duplicateContent}>
                          <strong>{child.reportNumber}</strong>
                          <span className={styles.duplicateTitle}>{child.title}</span>
                        </span>
                      </label>
                      <div className={styles.duplicateMeta}>
                        <span className={statusPillClass(child.status)}>
                          <Icon name={statusIconName(child.status)} size={10} aria-hidden />
                          {formatReportStatus(child.status)}
                        </span>
                        <span>{formatReportDate(child.submittedAt)}</span>
                        <span>{child.mediaCount} media</span>
                      </div>
                    </motion.li>
                  ))}
                </ul>
              </section>

              <div className={styles.actions}>
                <span className={styles.selectionHint}>
                  {selectedChildIds.length} of {selectedGroup.duplicateReports.length} selected
                </span>
                <Button
                  onClick={() => setIsMergeModalOpen(true)}
                  isLoading={isMerging}
                  disabled={selectedChildIds.length === 0}
                >
                  <Icon name="check" size={14} aria-hidden />
                  Approve and merge
                </Button>
              </div>
            </>
          )}
        </Card>
      </div>

      <Snack snack={snack} onClose={clearSnack} />
      <ActionConfirmModal
        isOpen={isMergeModalOpen}
        title="Confirm duplicate merge"
        description="This will approve the primary report, merge selected child evidence and co-reporters, then close selected child reports as merged duplicates."
        confirmLabel="Approve and merge"
        notesLabel="Merge reason (optional)"
        notesPlaceholder="Add optional merge context for the audit trail"
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
