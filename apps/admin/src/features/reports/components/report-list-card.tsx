'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { motion } from 'framer-motion';
import { Button, Icon } from '@/components/ui';
import type { ReportRow } from '@/features/reports/types';
import { formatReportDate, formatReportStatus, isReportFinalStatus, statusIconName } from '@/features/reports/utils/report-status';
import { queueMeta } from '@/features/reports/utils/queue-meta';
import styles from './report-list-card.module.css';

type ReportListCardProps = {
  report: ReportRow;
  onApprove?: (report: ReportRow) => void;
  onReject?: (report: ReportRow) => void;
};

type ReportListMobileCardProps = {
  report: ReportRow;
  index?: number;
  reducedMotion?: boolean;
  onApprove?: (report: ReportRow) => void;
  onReject?: (report: ReportRow) => void;
};

function statusClassName(status: ReportRow['status']) {
  const classMap: Record<ReportRow['status'], string> = {
    NEW: styles.statusNew,
    IN_REVIEW: styles.statusInReview,
    APPROVED: styles.statusApproved,
    DELETED: styles.statusDeleted,
  };
  return `${styles.statusPill} ${classMap[status]}`;
}

function preventNav(e: React.MouseEvent) {
  e.preventDefault();
  e.stopPropagation();
}

export function ReportListCard({ report, onApprove, onReject }: ReportListCardProps) {
  const pathname = usePathname();
  const isCurrentReport = pathname === `/dashboard/reports/${report.id}`;

  const href = `/dashboard/reports/${report.id}`;

  const showActions = Boolean(onApprove && onReject);
  const actionsDisabled = isReportFinalStatus(report.status);

  return (
    <Link
      href={href}
      className={styles.row}
      aria-current={isCurrentReport ? 'page' : undefined}
      role="listitem"
    >
      <span className={styles.cellReport}>{report.reportNumber}</span>
      <span className={styles.cellTitle}>{report.name}</span>
      <span className={styles.cellLocation}>
        <Icon name="location" size={12} />
        {report.location.trim() ? report.location : '—'}
      </span>
      <span className={styles.cellDate}>{formatReportDate(report.dateReportedAt)}</span>
      <span className={styles.cellStatus}>
        <span className={statusClassName(report.status)}>
          <Icon name={statusIconName(report.status)} size={12} />
          {formatReportStatus(report.status)}
        </span>
        <span className={styles.statusMeta}>
          {(report.status === 'NEW' || report.status === 'IN_REVIEW') && (
            <span className={styles.queueMeta}>
              {queueMeta(report.status).priority} · {queueMeta(report.status).slaLabel}
            </span>
          )}
          {(report.isPotentialDuplicate ||
            report.coReporterCount > 0 ||
            report.cleanupEffortLabel) && (
            <span className={styles.badges}>
              {report.cleanupEffortLabel ? (
                <span className={styles.badge} title="Estimated cleanup team size">
                  {report.cleanupEffortLabel}
                </span>
              ) : null}
              {report.isPotentialDuplicate && <span className={styles.badge}>Dup</span>}
              {report.coReporterCount > 0 && (
                <span className={styles.badge}>+{report.coReporterCount}</span>
              )}
            </span>
          )}
        </span>
      </span>
      <span className={`${styles.cellAction} ${actionsDisabled ? styles.cellActionDisabled : ''}`}>
        {showActions && (
          <>
            <Button
              variant="icon"
              size="sm"
              className={styles.actionBtn}
              disabled={actionsDisabled}
              onClick={(e) => {
                preventNav(e);
                onApprove?.(report);
              }}
              aria-label={actionsDisabled ? `${report.reportNumber} already has a final decision` : `Approve ${report.reportNumber}`}
              title={actionsDisabled ? 'No further actions' : 'Approve'}
            >
              <Icon name="check" size={14} aria-hidden />
            </Button>
            <Button
              variant="icon"
              size="sm"
              className={styles.actionBtn}
              disabled={actionsDisabled}
              onClick={(e) => {
                preventNav(e);
                onReject?.(report);
              }}
              aria-label={actionsDisabled ? `${report.reportNumber} already has a final decision` : `Reject ${report.reportNumber}`}
              title={actionsDisabled ? 'No further actions' : 'Reject'}
            >
              <Icon name="trash" size={14} aria-hidden />
            </Button>
          </>
        )}
        <Icon name="chevron-right" size={14} aria-hidden />
      </span>
    </Link>
  );
}

const ROW_STAGGER_DELAY = 0.03;
const MAX_STAGGER_DELAY = 0.15;

function getRowTransition(index: number, reducedMotion?: boolean) {
  if (reducedMotion) return { duration: 0 };
  const delay = Math.min(index * ROW_STAGGER_DELAY, MAX_STAGGER_DELAY);
  return { type: 'spring' as const, stiffness: 400, damping: 30, delay };
}

export function ReportListMobileCard({
  report,
  index = 0,
  reducedMotion,
  onApprove,
  onReject,
}: ReportListMobileCardProps) {
  const pathname = usePathname();
  const isCurrentReport = pathname === `/dashboard/reports/${report.id}`;

  const href = `/dashboard/reports/${report.id}`;

  const showActions = Boolean(onApprove && onReject);
  const actionsDisabled = isReportFinalStatus(report.status);

  return (
    <motion.article
      initial={reducedMotion ? false : { opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={getRowTransition(index, reducedMotion)}
    >
      <div className={styles.mobileCardWrapper}>
        <Link
          href={href}
          className={styles.mobileCard}
          aria-current={isCurrentReport ? 'page' : undefined}
          role="listitem"
        >
          <div className={styles.mobileMeta}>
            <strong>{report.reportNumber}</strong>
            <span>{formatReportDate(report.dateReportedAt)}</span>
          </div>
          <h3 className={styles.mobileTitle}>{report.name}</h3>
          <p className={styles.mobileLocation}>
            <Icon name="location" size={14} aria-hidden />
            {report.location.trim() ? report.location : '—'}
          </p>
        <div className={styles.mobileStatusRow}>
          <span className={statusClassName(report.status)}>
            <Icon name={statusIconName(report.status)} size={12} aria-hidden />
            {formatReportStatus(report.status)}
          </span>
          {(report.status === 'NEW' || report.status === 'IN_REVIEW') && (
            <span className={styles.mobileQueueMeta}>
              {queueMeta(report.status).priority} · {queueMeta(report.status).slaLabel}
            </span>
          )}
          {(report.isPotentialDuplicate ||
            report.coReporterCount > 0 ||
            report.cleanupEffortLabel) && (
              <span className={styles.badges}>
                {report.cleanupEffortLabel ? (
                  <span className={styles.badge} title="Estimated cleanup team size">
                    {report.cleanupEffortLabel}
                  </span>
                ) : null}
                {report.isPotentialDuplicate && <span className={styles.badge}>Dup</span>}
                {report.coReporterCount > 0 && (
                  <span className={styles.badge}>+{report.coReporterCount}</span>
                )}
              </span>
            )}
          </div>
          <span className={styles.mobileAction}>
            <Icon name="chevron-right" size={14} aria-hidden />
          </span>
        </Link>
        {showActions && (
          <div className={`${styles.mobileActions} ${actionsDisabled ? styles.mobileActionsDisabled : ''}`}>
            <Button
              variant="icon"
              size="sm"
              className={styles.actionBtn}
              disabled={actionsDisabled}
              onClick={() => onApprove?.(report)}
              aria-label={actionsDisabled ? `${report.reportNumber} already has a final decision` : `Approve ${report.reportNumber}`}
              title={actionsDisabled ? 'No further actions' : 'Approve'}
            >
              <Icon name="check" size={14} aria-hidden />
            </Button>
            <Button
              variant="icon"
              size="sm"
              className={styles.actionBtn}
              disabled={actionsDisabled}
              onClick={() => onReject?.(report)}
              aria-label={actionsDisabled ? `${report.reportNumber} already has a final decision` : `Reject ${report.reportNumber}`}
              title={actionsDisabled ? 'No further actions' : 'Reject'}
            >
              <Icon name="trash" size={14} aria-hidden />
            </Button>
          </div>
        )}
      </div>
    </motion.article>
  );
}
