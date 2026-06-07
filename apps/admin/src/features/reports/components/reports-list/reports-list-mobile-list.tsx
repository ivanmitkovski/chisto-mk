'use client';

import type { ReportRow } from '@/features/reports/types';
import { ReportListMobileCard } from '@/features/reports/components/report-list-card';
import styles from '@/features/reports/components/reports-list.module.css';

type ReportsListMobileListProps = {
  reports: ReportRow[];
  highlightedReportIds: Set<string>;
  reducedMotion: boolean;
  onApprove: (report: ReportRow) => void;
  onReject: (report: ReportRow) => void;
};

export function ReportsListMobileList({
  reports,
  highlightedReportIds,
  reducedMotion,
  onApprove,
  onReject,
}: ReportsListMobileListProps) {
  return (
    <div className={styles.mobileList} role="list">
      {reports.map((report, index) => (
        <div
          key={`mobile-wrap-${report.id}`}
          className={highlightedReportIds.has(report.id) ? styles.mobileRowNew : undefined}
        >
          <ReportListMobileCard
            key={`mobile-${report.id}`}
            report={report}
            index={index}
            reducedMotion={reducedMotion}
            onApprove={onApprove}
            onReject={onReject}
          />
        </div>
      ))}
    </div>
  );
}
