'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { Icon } from '@/components/ui';
import type { ReportDetail } from '../../types';
import { statusIconName } from '../../utils/report-status';
import { useFormatReportStatus } from '../../hooks/use-format-report-status';
import type { ReportPillClassNames } from '../../utils/report-pills';
import { reportPriorityPillClass, reportStatusPillClass } from '../../utils/report-pills';
import styles from './report-review-header.module.css';

type ReportReviewHeaderProps = {
  report: ReportDetail;
  pillStyles: ReportPillClassNames;
};

export function ReportReviewHeader({ report, pillStyles }: ReportReviewHeaderProps) {
  const t = useTranslations('reports');
  const formatStatus = useFormatReportStatus();
  const tSeverity = useTranslations('reports.severity');

  return (
    <>
      <header className={styles.header}>
        <div>
          <p className={styles.kicker}>{t('moderationWorkspace')}</p>
          <h2 className={styles.title}>{report.title}</h2>
        </div>
        <div className={styles.headerPills}>
          <span className={reportStatusPillClass(report.status, pillStyles)}>
            <Icon name={statusIconName(report.status)} size={12} />
            {formatStatus(report.status)}
          </span>
          <span className={reportPriorityPillClass(report.priority, pillStyles)}>
            {t('prioritySuffix', { priority: tSeverity(report.priority) })}
          </span>
        </div>
      </header>
      {report.isPotentialDuplicate ? (
        <div className={styles.duplicateNotice} role="status">
          <p className={styles.duplicateNoticeText}>
            {report.potentialDuplicateOfReportNumber
              ? t('duplicateOfSpecific', { reportNumber: report.potentialDuplicateOfReportNumber })
              : t('duplicateOfAnother')}
            {report.coReporters.length > 0
              ? t('alsoReportedBy', { names: report.coReporters.join(', ') })
              : ''}
          </p>
          <Link href={`/dashboard/reports/duplicates?reportId=${report.id}`} className={styles.duplicateNoticeLink}>
            {t('viewAllDuplicateReports')}
            <Icon name="document-forward" size={14} />
          </Link>
        </div>
      ) : null}
    </>
  );
}
