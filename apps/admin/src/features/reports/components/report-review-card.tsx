'use client';

import { motion } from 'framer-motion';
import { Button, Card, Icon, Snack } from '@/components/ui';
import { useReportReview } from '../hooks/use-report-review';
import { ReportDetail } from '../types';
import { statusIconName } from '../utils/report-status';
import styles from './report-review-card.module.css';

type ReportReviewCardProps = {
  report: ReportDetail;
};

function statusClassName(status: ReportDetail['status']) {
  const statusClassByName: Record<ReportDetail['status'], string> = {
    NEW: styles.statusNew,
    IN_REVIEW: styles.statusInReview,
    APPROVED: styles.statusApproved,
    DELETED: styles.statusDeleted,
  };

  return `${styles.statusPill} ${statusClassByName[status]}`;
}

export function ReportReviewCard({ report }: ReportReviewCardProps) {
  const { report: currentReport, isUpdating, snack, approveReport, rejectReport, clearSnack } = useReportReview(report);

  return (
    <motion.div
      initial={{ opacity: 0, y: 14 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.28, ease: 'easeOut' }}
    >
      <Card className={styles.card}>
        <h2 className={styles.title}>Report Review</h2>
        <div className={styles.grid}>
          <motion.article className={styles.panel} whileHover={{ y: -2 }} transition={{ duration: 0.15 }}>
            <div className={styles.image} />
            <div className={styles.body}>
              <div className={styles.statusRow}>
                <span>
                  STATUS:{' '}
                  <span className={statusClassName(currentReport.status)}>
                    <Icon name={statusIconName(currentReport.status)} size={12} />
                    {currentReport.status}
                  </span>
                </span>
                <span className={styles.location}>
                  <Icon name="location" size={14} />
                  {currentReport.location}
                </span>
              </div>
              <h3 className={styles.reportTitle}>{currentReport.title}</h3>
              <p className={styles.reportText}>{currentReport.description}</p>
              <div className={styles.actions}>
                <Button onClick={approveReport} isLoading={isUpdating}>
                  <Icon name="check" size={14} />
                  Approve
                </Button>
                <Button variant="outline" onClick={rejectReport} isLoading={isUpdating}>
                  <Icon name="trash" size={14} />
                  Reject
                </Button>
              </div>
            </div>
          </motion.article>
          <motion.article className={styles.panel} whileHover={{ y: -2 }} transition={{ duration: 0.15 }}>
            <div className={styles.map} />
          </motion.article>
        </div>
        <Snack snack={snack} onClose={clearSnack} />
      </Card>
    </motion.div>
  );
}
