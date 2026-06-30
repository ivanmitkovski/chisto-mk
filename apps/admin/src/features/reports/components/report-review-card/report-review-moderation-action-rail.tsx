'use client';

import type { KeyboardEvent as ReactKeyboardEvent, MutableRefObject } from 'react';
import { useTranslations } from 'next-intl';
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
  const t = useTranslations('reports.moderationActions');
  const statusPillClass = reportStatusPillClass(currentReport.status, pillStyles);

  return (
    <motion.article
      className={`${styles.panel} ${styles.railPanel} ${allActionsDisabled ? styles.actionsResolved : ''}`}
      {...(!allActionsDisabled && { whileHover: { y: -2 } })}
      transition={{ duration: 0.15 }}
    >
      <h3 className={styles.railTitle}>{t('title')}</h3>
      {allActionsDisabled ? (
        <div className={styles.resolvedState} role="status">
          <span className={statusPillClass}>
            <Icon name={statusIconName(currentReport.status)} size={14} />
            {currentReport.status === 'APPROVED' ? t('reportApproved') : t('reportRejected')}
          </span>
          <p className={styles.railText}>{t('lifecycleComplete')}</p>
        </div>
      ) : (
        <>
          <p className={styles.railText}>{t('hint')}</p>
          <p className={styles.shortcutHint}>{t('shortcutHint')}</p>
          <div
            className={styles.actions}
            role="toolbar"
            aria-label={t('toolbarAria')}
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
                    ? t('aria.setInReviewAlready')
                    : t('aria.setInReviewDisabled')
                  : t('aria.setInReview')
              }
              ref={(element) => {
                actionButtonsRef.current[0] = element;
              }}
            >
              <Icon name="document-text" size={14} />
              {t('setInReview')}
            </Button>
            <Button
              onClick={() => onSelectAction('approve')}
              isLoading={isUpdating}
              disabled={isApproveDisabled}
              aria-label={isApproveDisabled ? t('aria.approveDisabled') : t('aria.approve')}
              ref={(element) => {
                actionButtonsRef.current[1] = element;
              }}
            >
              <Icon name="check" size={14} />
              {t('approveReport')}
            </Button>
            <Button
              variant="outline"
              onClick={() => onSelectAction('reject')}
              isLoading={isUpdating}
              disabled={isRejectDisabled}
              aria-label={isRejectDisabled ? t('aria.rejectDisabled') : t('aria.reject')}
              ref={(element) => {
                actionButtonsRef.current[2] = element;
              }}
            >
              <Icon name="trash" size={14} />
              {t('rejectReport')}
            </Button>
          </div>
        </>
      )}
    </motion.article>
  );
}
