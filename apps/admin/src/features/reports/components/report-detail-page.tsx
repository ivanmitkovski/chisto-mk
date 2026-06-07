'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { motion, useReducedMotion } from 'framer-motion';
import { Button, Icon } from '@/components/ui';
import { useWorkspaceRefresh } from '@/features/admin-shell';
import { ReportReviewCard } from './report-review-card';
import { ReportViewersBanner } from './report-viewers-banner';
import type { ReportDetail } from '@/features/reports/types';
import { useReportViewerPresence } from '../hooks/use-report-viewer-presence';
import { statusIconName } from '@/features/reports/utils/report-status';
import { useFormatReportStatus } from '@/features/reports/hooks/use-format-report-status';
import type { ReportPillClassNames } from '@/features/reports/utils/report-pills';
import { reportPriorityPillClass, reportStatusPillClass } from '@/features/reports/utils/report-pills';
import type { EligibleModerator } from '../data/eligible-moderators';
import styles from './report-detail-page.module.css';

type ReportDetailPageProps = {
  report: ReportDetail;
  moderatorId?: string;
  moderatorDisplayName?: string;
  viewerRole?: string;
  eligibleModerators?: EligibleModerator[];
};

const pillStyles = styles as ReportPillClassNames;

const SPRING = { type: 'spring' as const, stiffness: 400, damping: 30 };

export function ReportDetailPage({
  report,
  moderatorId,
  moderatorDisplayName,
  viewerRole,
  eligibleModerators = [],
}: ReportDetailPageProps) {
  const router = useRouter();
  const reducedMotion = useReducedMotion();
  const { refresh, isRefreshing } = useWorkspaceRefresh();
  const t = useTranslations('reports');
  const formatStatus = useFormatReportStatus();
  const tSeverity = useTranslations('reports.severity');

  const { otherViewers } = useReportViewerPresence({
    reportId: report.id,
    ...(moderatorId ? { moderatorId } : {}),
    ...(moderatorDisplayName ? { moderatorDisplayName } : {}),
  });

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
          aria-label={t('backToReportsList')}
        >
          <Icon name="chevron-left" size={18} aria-hidden />
          {t('backToReports')}
        </Link>
        <div className={styles.headerCenter}>
          <span className={styles.reportNumber}>{report.reportNumber}</span>
          <h2 className={styles.title}>{report.title}</h2>
        </div>
        <div className={styles.headerPills}>
          <Button
            variant="icon"
            aria-label={t('refreshReportAria')}
            onClick={refresh}
            disabled={isRefreshing}
            className={styles.refreshBtn}
          >
            <Icon name="refresh" size={16} {...(isRefreshing && { className: styles.spinning })} />
          </Button>
          <Link href="/dashboard/operations" className={styles.opsLink}>
            {t('outbox')}
          </Link>
          <span className={reportStatusPillClass(report.status, pillStyles)}>
            <Icon name={statusIconName(report.status)} size={12} />
            {formatStatus(report.status)}
          </span>
          <span className={reportPriorityPillClass(report.priority, pillStyles)}>
            {t('prioritySuffix', { priority: tSeverity(report.priority) })}
          </span>
        </div>
      </header>
      <ReportViewersBanner viewers={otherViewers} />
      {report.isPotentialDuplicate ? (
        <div className={styles.duplicateNotice} role="status">
          <Icon name="alert-triangle" size={16} aria-hidden />
          <span>
            {t('duplicateNotice', {
              ofReport: report.potentialDuplicateOfReportNumber
                ? t('duplicateOfReport', { reportNumber: report.potentialDuplicateOfReportNumber })
                : '',
            })}{' '}
            <Link href={`/dashboard/reports/duplicates?reportId=${report.id}`} className={styles.duplicateNoticeLink}>
              {t('reviewDuplicateGroups')}
            </Link>
          </span>
        </div>
      ) : null}
      <div className={styles.body}>
        <ReportReviewCard
          report={report}
          onReportUpdated={() => router.refresh()}
          hideHeader
          fullPage
          otherViewersCount={otherViewers.length}
          eligibleModerators={eligibleModerators}
          {...(viewerRole ? { viewerRole } : {})}
          {...(moderatorId ? { moderatorId } : {})}
          {...(moderatorDisplayName ? { moderatorDisplayName } : {})}
        />
      </div>
    </motion.div>
  );
}
