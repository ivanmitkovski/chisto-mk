'use client';

import Link from 'next/link';
import { Fragment, type ReactNode } from 'react';
import { useTranslations } from 'next-intl';
import { EmptyState } from '../empty-state';
import { SkeletonTable } from '../skeleton';
import styles from './data-table.module.css';

export type DataTableColumn<T> = {
  key: string;
  header: string;
  sortable?: boolean;
  render: (row: T) => React.ReactNode;
  renderHeader?: () => React.ReactNode;
  renderMobile?: (row: T) => React.ReactNode;
  /** When true, column is omitted from the default per-column mobile stack (use renderMobileCard instead). */
  mobileHidden?: boolean;
};

export type DataTableProps<T> = {
  columns: DataTableColumn<T>[];
  data: T[];
  getRowId: (row: T) => string;
  caption?: string;
  emptyMessage?: string;
  meta?: React.ReactNode;
  pagination?: React.ReactNode;
  sortKey?: string;
  sortDir?: 'asc' | 'desc';
  onSort?: (key: string) => void;
  getRowClassName?: (row: T) => string | undefined;
  getRowAriaCurrent?: (row: T) => boolean;
  getMobileCardClassName?: (row: T) => string | undefined;
  renderAfterRow?: (row: T) => React.ReactNode;
  renderMobileCard?: (row: T) => React.ReactNode;
  tableClassName?: string;
  wrapClassName?: string;
  isLoading?: boolean;
  loadingRowCount?: number;
};

export function DataTable<T>({
  columns,
  data,
  getRowId,
  caption,
  emptyMessage,
  meta,
  pagination,
  sortKey,
  sortDir,
  onSort,
  getRowClassName,
  getRowAriaCurrent,
  getMobileCardClassName,
  renderAfterRow,
  renderMobileCard,
  tableClassName,
  wrapClassName,
  isLoading = false,
  loadingRowCount = 8,
}: DataTableProps<T>) {
  const t = useTranslations('ui');
  const resolvedEmptyMessage = emptyMessage ?? t('noData');
  const tableClass = [styles.table, tableClassName].filter(Boolean).join(' ');
  const wrapClass = [styles.wrap, wrapClassName].filter(Boolean).join(' ');
  const mobileColumns = columns.filter((col) => !col.mobileHidden);

  if (isLoading) {
    return (
      <div aria-busy="true" role="status">
        <SkeletonTable rows={loadingRowCount} cols={columns.length} />
      </div>
    );
  }

  return (
    <div>
      <div className={wrapClass}>
        {data.length > 0 ? (
          <>
            <div className={styles.tableWrap}>
              <table className={tableClass}>
                {caption ? <caption className={styles.caption}>{caption}</caption> : null}
                <thead>
                  <tr>
                    {columns.map((col) => (
                      <th
                        key={col.key}
                        scope="col"
                        aria-sort={
                          col.sortable && onSort
                            ? sortKey === col.key
                              ? sortDir === 'asc'
                                ? 'ascending'
                                : 'descending'
                              : 'none'
                            : undefined
                        }
                      >
                        {col.renderHeader ? (
                          col.renderHeader()
                        ) : col.sortable && onSort ? (
                          <button
                            type="button"
                            className={styles.sortButton}
                            onClick={() => onSort(col.key)}
                          >
                            {col.header}
                            {sortKey === col.key && (
                              <span className={styles.sortIcon} aria-hidden>
                                {sortDir === 'asc' ? ' ↑' : ' ↓'}
                              </span>
                            )}
                          </button>
                        ) : (
                          col.header
                        )}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {data.map((row) => {
                    const rowClass = getRowClassName?.(row);
                    const after = renderAfterRow?.(row);
                    return (
                      <Fragment key={getRowId(row)}>
                        <tr
                          className={rowClass}
                          aria-current={getRowAriaCurrent?.(row) ? 'true' : undefined}
                        >
                          {columns.map((col) => (
                            <td key={col.key}>{col.render(row)}</td>
                          ))}
                        </tr>
                        {after}
                      </Fragment>
                    );
                  })}
                </tbody>
              </table>
            </div>
            <div className={styles.mobileList}>
              {data.map((row) => {
                const cardClass = [styles.mobileCard, getMobileCardClassName?.(row)]
                  .filter(Boolean)
                  .join(' ');
                return (
                  <div key={getRowId(row)} className={cardClass}>
                    {renderMobileCard
                      ? renderMobileCard(row)
                      : mobileColumns.map((col) => (
                          <div key={col.key}>
                            {(col.renderMobile ?? col.render)(row)}
                          </div>
                        ))}
                  </div>
                );
              })}
            </div>
          </>
        ) : (
          <EmptyState title={resolvedEmptyMessage} />
        )}
      </div>
      {meta && <p className={styles.meta}>{meta}</p>}
      {pagination}
    </div>
  );
}

export function DataTableLink({
  href,
  children,
}: {
  href: string;
  children: React.ReactNode;
}) {
  return (
    <Link className={styles.link} href={href}>
      {children}
    </Link>
  );
}

export function DataTableMobileField({
  label,
  children,
}: {
  label: string;
  children: ReactNode;
}) {
  return (
    <div className={styles.mobileField}>
      <span className={styles.mobileFieldLabel}>{label}</span>
      <span className={styles.mobileFieldValue}>{children}</span>
    </div>
  );
}
