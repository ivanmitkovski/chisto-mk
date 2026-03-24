'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { motion, useReducedMotion } from 'framer-motion';
import { Icon } from '@/components/ui';
import { ReportReviewCard } from './report-review-card';
import type { ReportDetail } from '@/features/reports/types';
import { formatReportStatus, statusIconName } from '@/features/reports/utils/report-status';
import styles from './report-detail-page.module.css';

type ReportDetailPageProps = {
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

function priorityClassName(priority: ReportDetail['priority']) {
  const priorityClassByName: Record<ReportDetail['priority'], string> = {
    LOW: styles.priorityLow,
    MEDIUM: styles.priorityMedium,
    HIGH: styles.priorityHigh,
    CRITICAL: styles.priorityCritical,
  };
  return `${styles.priorityPill} ${priorityClassByName[priority]}`;
}

const SPRING = { type: 'spring' as const, stiffness: 400, damping: 30 };

export function ReportDetailPage({ report }: ReportDetailPageProps) {
  const router = useRouter();
  const reducedMotion = useReducedMotion();

  return (
    <motion.div
      className={styles.page}
      initial={reducedMotion ? false : { opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={reducedMotion ? { duration: 0 } : SPRING}
    >
      <header className={styles.header}>
        <Link
          href="/dashboard/reports"
          className={styles.backLink}
          aria-label="Back to reports list"
        >
          <Icon name="chevron-left" size={18} aria-hidden />
          Reports
        </Link>
        <div className={styles.headerCenter}>
          <span className={styles.reportNumber}>{report.reportNumber}</span>
          <h1 className={styles.title}>{report.title}</h1>
        </div>
        <div className={styles.headerPills}>
          <span className={statusClassName(report.status)}>
            <Icon name={statusIconName(report.status)} size={12} />
            {formatReportStatus(report.status)}
          </span>
          <span className={priorityClassName(report.priority)}>
            {report.priority} priority
          </span>
        </div>
      </header>
      <div className={styles.body}>
        <ReportReviewCard report={report} onReportUpdated={() => router.refresh()} hideHeader fullPage />
      </div>
    </motion.div>
  );
}
