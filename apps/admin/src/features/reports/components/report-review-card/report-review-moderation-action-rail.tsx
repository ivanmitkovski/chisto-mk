'use client';

import type { KeyboardEvent as ReactKeyboardEvent, MutableRefObject } from 'react';
import { motion } from 'framer-motion';
import { Button, Icon } from '@/components/ui';
import type { ReportDetail } from '../../types';
import { statusIconName } from '../../utils/report-status';
import type { ReportPillClassNames } from '../../utils/report-pills';
import { reportStatusPillClass } from '../../utils/report-pills';
import styles from '../report-review-card.module.css';

type ReportReviewModerationActionRailProps = {
  currentReport: ReportDetail;
  pillStyles: ReportPillClassNames;
  allActionsDisabled: boolean;
  isUpdating: boolean;
  isSetInReviewDisabled: boolean;
  isApproveDisabled: boolean;
  isRejectDisabled: boolean;
  actionButtonsRef: MutableRefObject<Array<HTMLButtonElement | null>>;
  onActionRailKeyDown: (event: ReactKeyboardEvent<HTMLDivElement>) => void;
  onSelectAction: (action: 'set-in-review' | 'approve' | 'reject') => void;
};

export function ReportReviewModerationActionRail({
  currentReport,
  pillStyles,
  allActionsDisabled,
  isUpdating,
  isSetInReviewDisabled,
  isApproveDisabled,
  isRejectDisabled,
  actionButtonsRef,
  onActionRailKeyDown,
  onSelectAction,
}: ReportReviewModerationActionRailProps) {
  const statusPillClass = reportStatusPillClass(currentReport.status, pillStyles);

  return (
    <motion.article
      className={`${styles.panel} ${styles.railPanel} ${allActionsDisabled ? styles.actionsResolved : ''}`}
      {...(!allActionsDisabled && { whileHover: { y: -2 } })}
      transition={{ duration: 0.15 }}
    >
      <h3 className={styles.railTitle}>Moderation actions</h3>
      {allActionsDisabled ? (
        <div className={styles.resolvedState} role="status">
          <span className={statusPillClass}>
            <Icon name={statusIconName(currentReport.status)} size={14} />
            {currentReport.status === 'APPROVED' ? 'Report approved' : 'Report rejected'}
          </span>
          <p className={styles.railText}>
            No further actions available. The lifecycle for this report is complete.
          </p>
        </div>
      ) : (
        <>
          <p className={styles.railText}>
            Apply an explicit decision and keep the lifecycle clean. Every action writes a timeline entry.
          </p>
          <p className={styles.shortcutHint}>Tip: use Arrow keys to move between actions.</p>
          <div
            className={styles.actions}
            role="toolbar"
            aria-label="Moderation actions"
            aria-disabled={allActionsDisabled}
            onKeyDown={onActionRailKeyDown}
          >
            <Button
              variant="outline"
              onClick={() => onSelectAction('set-in-review')}
              isLoading={isUpdating}
              disabled={isSetInReviewDisabled}
              aria-label={
                isSetInReviewDisabled
                  ? currentReport.status === 'IN_REVIEW'
                    ? 'Set in review (already in review)'
                    : 'Set in review (no further actions)'
                  : 'Set in review'
              }
              ref={(element) => {
                actionButtonsRef.current[0] = element;
              }}
            >
              <Icon name="document-text" size={14} />
              Set in review
            </Button>
            <Button
              onClick={() => onSelectAction('approve')}
              isLoading={isUpdating}
              disabled={isApproveDisabled}
              aria-label={isApproveDisabled ? 'Approve report (no further actions)' : 'Approve report'}
              ref={(element) => {
                actionButtonsRef.current[1] = element;
              }}
            >
              <Icon name="check" size={14} />
              Approve report
            </Button>
            <Button
              variant="outline"
              onClick={() => onSelectAction('reject')}
              isLoading={isUpdating}
              disabled={isRejectDisabled}
              aria-label={isRejectDisabled ? 'Reject report (no further actions)' : 'Reject report'}
              ref={(element) => {
                actionButtonsRef.current[2] = element;
              }}
            >
              <Icon name="trash" size={14} />
              Reject report
            </Button>
          </div>
        </>
      )}
    </motion.article>
  );
}
