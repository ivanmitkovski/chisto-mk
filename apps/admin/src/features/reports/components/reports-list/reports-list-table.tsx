'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { Icon, type IconName } from '@/components/ui';
import { getColumnOptions } from '@/features/reports/config/table';
import type { ReportRow, SortKey } from '@/features/reports/types';
import { ReportListCard } from '@/features/reports/components/report-list-card';
import styles from '@/features/reports/components/reports-list.module.css';

type ReportsListTableProps = {
  reports: ReportRow[];
  highlightedReportIds: Set<string>;
  isOverview: boolean;
  onSort: (key: SortKey) => void;
  sortIconName: (key: SortKey) => IconName;
  ariaSortValue: (key: SortKey) => 'none' | 'ascending' | 'descending';
  sortHref: (key: SortKey) => string;
  onApprove: (report: ReportRow) => void;
  onReject: (report: ReportRow) => void;
};

export function ReportsListTable({
  reports,
  highlightedReportIds,
  isOverview,
  onSort,
  sortIconName,
  ariaSortValue,
  sortHref,
  onApprove,
  onReject,
}: ReportsListTableProps) {
  const t = useTranslations('reports');
  const columns = getColumnOptions(t);

  return (
    <div className={styles.tableWrapper}>
      <div className={styles.table}>
        <div className={styles.tableHeader} role="row">
          {columns.map((col) => (
            <span key={col.key} className={styles.headerCell}>
              {isOverview ? (
                <button
                  type="button"
                  className={styles.headerSortLink}
                  aria-sort={ariaSortValue(col.key)}
                  onClick={() => onSort(col.key)}
                >
                  {col.label}
                  <Icon name={sortIconName(col.key)} size={13} className={styles.headerSortIcon} aria-hidden />
                </button>
              ) : (
                <Link
                  href={sortHref(col.key)}
                  className={styles.headerSortLink}
                  aria-sort={ariaSortValue(col.key)}
                >
                  {col.label}
                  <Icon name={sortIconName(col.key)} size={13} className={styles.headerSortIcon} aria-hidden />
                </Link>
              )}
            </span>
          ))}
          <span className={`${styles.headerCell} ${styles.actionsHeader}`}>{t('columnsActions')}</span>
        </div>
        <div className={styles.rowList} role="list">
          {reports.map((report) => (
            <div
              key={report.id}
              className={`${styles.tableRow} ${highlightedReportIds.has(report.id) ? styles.tableRowNew : ''}`}
            >
              <ReportListCard report={report} onApprove={onApprove} onReject={onReject} />
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
