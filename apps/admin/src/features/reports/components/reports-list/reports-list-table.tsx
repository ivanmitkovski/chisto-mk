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
        <table className={styles.headerTable}>
          <caption className={styles.headerCaption}>{t('tableCaption')}</caption>
          <thead>
            <tr>
              {columns.map((col) => (
                <th key={col.key} scope="col" aria-sort={ariaSortValue(col.key)}>
                  {isOverview ? (
                    <button
                      type="button"
                      className={styles.headerSortLink}
                      onClick={() => onSort(col.key)}
                    >
                      {col.label}
                      <Icon name={sortIconName(col.key)} size={13} className={styles.headerSortIcon} aria-hidden />
                    </button>
                  ) : (
                    <Link href={sortHref(col.key)} className={styles.headerSortLink}>
                      {col.label}
                      <Icon name={sortIconName(col.key)} size={13} className={styles.headerSortIcon} aria-hidden />
                    </Link>
                  )}
                </th>
              ))}
              <th scope="col" className={styles.actionsHeader}>
                {t('columnsActions')}
              </th>
            </tr>
          </thead>
        </table>
        <div className={styles.rowList}>
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
