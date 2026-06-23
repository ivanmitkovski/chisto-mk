'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { Button, Icon } from '@/components/ui';
import { Can } from '@/lib/auth/rbac';
import type { ReportRow } from '@/features/reports/types';
import { formatReportDate, isReportFinalStatus, statusIconName } from '@/features/reports/utils/report-status';
import { useFormatReportStatus } from '@/features/reports/hooks/use-format-report-status';
import { formatQueuePriority, queueMeta } from '@/features/reports/utils/queue-meta';
import styles from './report-list-card.module.css';

type ReportListCardProps = {
  report: ReportRow;
  onApprove?: (report: ReportRow) => void;
  onReject?: (report: ReportRow) => void;
};

type ReportListMobileCardProps = {
  report: ReportRow;
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

function useReportListLabels() {
  const t = useTranslations('reports');
  const formatStatus = useFormatReportStatus();
  const formatQueue = (status: ReportRow['status']) => {
    const meta = queueMeta(status, t);
    return `${formatQueuePriority(meta.priority, t)} · ${meta.slaLabel}`;
  };
  return { t, formatStatus, formatQueue };
}

export function ReportListCard({ report, onApprove, onReject }: ReportListCardProps) {
  const pathname = usePathname();
  const { t, formatStatus, formatQueue } = useReportListLabels();
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
        <Icon name="location" size={12} className={styles.cellLocationIcon} aria-hidden />
        <span className={styles.cellLocationText}>
          {report.location.trim() ? report.location : '—'}
        </span>
      </span>
      <span className={styles.cellDate}>{formatReportDate(report.dateReportedAt)}</span>
      <span className={styles.cellStatus}>
        <span className={statusClassName(report.status)}>
          <Icon name={statusIconName(report.status)} size={12} />
          {formatStatus(report.status)}
        </span>
        <span className={styles.statusMeta}>
          {(report.status === 'NEW' || report.status === 'IN_REVIEW') && (
            <span className={styles.queueMeta}>
              {formatQueue(report.status)}
            </span>
          )}
          {(report.isPotentialDuplicate ||
            report.coReporterCount > 0 ||
            report.cleanupEffortLabel) && (
            <span className={styles.badges}>
              {report.cleanupEffortLabel ? (
                <span className={styles.badge} title={t('list.estimatedCleanupTeamSize')}>
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
          <Can permission="reports:moderate">
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
              aria-label={
                actionsDisabled
                  ? t('list.finalDecisionAria', { reportNumber: report.reportNumber })
                  : t('list.approveAria', { reportNumber: report.reportNumber })
              }
              title={actionsDisabled ? t('list.noFurtherActions') : t('list.approve')}
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
              aria-label={
                actionsDisabled
                  ? t('list.finalDecisionAria', { reportNumber: report.reportNumber })
                  : t('list.rejectAria', { reportNumber: report.reportNumber })
              }
              title={actionsDisabled ? t('list.noFurtherActions') : t('list.reject')}
            >
              <Icon name="trash" size={14} aria-hidden />
            </Button>
            </>
          </Can>
        )}
        <Icon name="chevron-right" size={14} aria-hidden />
      </span>
    </Link>
  );
}

export function ReportListMobileCard({
  report,
  onApprove,
  onReject,
}: ReportListMobileCardProps) {
  const pathname = usePathname();
  const { t, formatStatus, formatQueue } = useReportListLabels();
  const isCurrentReport = pathname === `/dashboard/reports/${report.id}`;

  const href = `/dashboard/reports/${report.id}`;

  const showActions = Boolean(onApprove && onReject);
  const actionsDisabled = isReportFinalStatus(report.status);

  return (
    <article>
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
            <Icon name="location" size={14} className={styles.cellLocationIcon} aria-hidden />
            <span className={styles.cellLocationText}>
              {report.location.trim() ? report.location : '—'}
            </span>
          </p>
        <div className={styles.mobileStatusRow}>
          <span className={statusClassName(report.status)}>
            <Icon name={statusIconName(report.status)} size={12} aria-hidden />
            {formatStatus(report.status)}
          </span>
          {(report.status === 'NEW' || report.status === 'IN_REVIEW') && (
            <span className={styles.mobileQueueMeta}>
              {formatQueue(report.status)}
            </span>
          )}
          {(report.isPotentialDuplicate ||
            report.coReporterCount > 0 ||
            report.cleanupEffortLabel) && (
              <span className={styles.badges}>
                {report.cleanupEffortLabel ? (
                  <span className={styles.badge} title={t('list.estimatedCleanupTeamSize')}>
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
          <Can permission="reports:moderate">
            <div className={`${styles.mobileActions} ${actionsDisabled ? styles.mobileActionsDisabled : ''}`}>
              <Button
                variant="icon"
                size="sm"
                className={styles.actionBtn}
                disabled={actionsDisabled}
                onClick={() => onApprove?.(report)}
                aria-label={
                  actionsDisabled
                    ? t('list.finalDecisionAria', { reportNumber: report.reportNumber })
                    : t('list.approveAria', { reportNumber: report.reportNumber })
                }
                title={actionsDisabled ? t('list.noFurtherActions') : t('list.approve')}
              >
                <Icon name="check" size={14} aria-hidden />
              </Button>
              <Button
                variant="icon"
                size="sm"
                className={styles.actionBtn}
                disabled={actionsDisabled}
                onClick={() => onReject?.(report)}
                aria-label={
                  actionsDisabled
                    ? t('list.finalDecisionAria', { reportNumber: report.reportNumber })
                    : t('list.rejectAria', { reportNumber: report.reportNumber })
                }
                title={actionsDisabled ? t('list.noFurtherActions') : t('list.reject')}
              >
                <Icon name="trash" size={14} aria-hidden />
              </Button>
            </div>
          </Can>
        )}
      </div>
    </article>
  );
}
