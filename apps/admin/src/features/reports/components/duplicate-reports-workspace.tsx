'use client';

import { useState } from 'react';
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

export function DuplicateReportsWorkspace({
  initialGroups,
  initialSelectedGroupId = null,
}: DuplicateReportsWorkspaceProps) {
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
    }
  }

  return (
    <>
      <div className={styles.layout}>
        <Card className={styles.groupsPanel}>
          <div className={styles.panelHeader}>
            <h2 className={styles.panelTitle}>Duplicate groups</h2>
            <p className={styles.panelSubtitle}>{groups.length} groups found</p>
          </div>

          <div className={styles.groupsList}>
            {groups.map((group) => (
              <button
                key={group.primaryReport.id}
                type="button"
                className={`${styles.groupButton} ${
                  selectedGroupId === group.primaryReport.id ? styles.groupButtonActive : ''
                }`}
                onClick={() => setSelectedGroupId(group.primaryReport.id)}
              >
                <span className={styles.groupButtonTop}>
                  <strong>{group.primaryReport.reportNumber}</strong>
                  <span className={styles.groupCount}>{group.totalReports} reports</span>
                </span>
                <span>{group.primaryReport.title}</span>
                <span className={styles.groupMeta}>
                  <Icon name="location" size={12} />
                  {group.primaryReport.location}
                </span>
              </button>
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
                  Primary report: <strong>{selectedGroup.primaryReport.reportNumber}</strong>
                </p>
              </div>

              <section className={styles.primarySection}>
                <h3>Primary report</h3>
                <article className={styles.primaryCard}>
                  <p className={styles.primaryTitle}>{selectedGroup.primaryReport.title}</p>
                  <p className={styles.metaLine}>
                    <Icon name="location" size={13} />
                    {selectedGroup.primaryReport.location}
                  </p>
                  <p className={styles.metaLine}>
                    <Icon name={statusIconName(selectedGroup.primaryReport.status)} size={13} />
                    {formatReportStatus(selectedGroup.primaryReport.status)} •{' '}
                    {formatReportDate(selectedGroup.primaryReport.submittedAt)}
                  </p>
                </article>
              </section>

              <section className={styles.duplicatesSection}>
                <div className={styles.duplicatesHeader}>
                  <h3>Child duplicates</h3>
                  <Button variant="outline" size="sm" onClick={selectAllChildren}>
                    Select all
                  </Button>
                </div>

                <ul className={styles.duplicatesList}>
                  {selectedGroup.duplicateReports.map((child) => (
                    <li key={child.id} className={styles.duplicateRow}>
                      <label className={styles.checkboxLabel}>
                        <input
                          type="checkbox"
                          checked={selectedChildIds.includes(child.id)}
                          onChange={() => toggleChildSelection(child.id)}
                        />
                        <span>
                          <strong>{child.reportNumber}</strong> — {child.title}
                        </span>
                      </label>
                      <span className={styles.duplicateMeta}>
                        {formatReportStatus(child.status)} • {formatReportDate(child.submittedAt)} • {child.mediaCount}{' '}
                        media
                      </span>
                    </li>
                  ))}
                </ul>
              </section>

              <div className={styles.actions}>
                <Button onClick={() => setIsMergeModalOpen(true)} isLoading={isMerging}>
                  <Icon name="check" size={14} />
                  Approve and merge selected
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
