'use client';

import Link from 'next/link';
import styles from './data-table.module.css';

export type DataTableColumn<T> = {
  key: string;
  header: string;
  sortable?: boolean;
  render: (row: T) => React.ReactNode;
  renderMobile?: (row: T) => React.ReactNode;
};

type DataTableProps<T> = {
  columns: DataTableColumn<T>[];
  data: T[];
  getRowId: (row: T) => string;
  emptyMessage?: string;
  meta?: React.ReactNode;
  pagination?: React.ReactNode;
  sortKey?: string;
  sortDir?: 'asc' | 'desc';
  onSort?: (key: string) => void;
};

export function DataTable<T>({
  columns,
  data,
  getRowId,
  emptyMessage = 'No data',
  meta,
  pagination,
  sortKey,
  sortDir,
  onSort,
}: DataTableProps<T>) {
  return (
    <div>
      <div className={styles.wrap}>
        {data.length > 0 ? (
          <>
            <div className={styles.tableWrap}>
              <table className={styles.table}>
                <thead>
                  <tr>
                    {columns.map((col) => (
                      <th key={col.key}>
                        {col.sortable && onSort ? (
                          <button
                            type="button"
                            className={styles.sortButton}
                            onClick={() => onSort(col.key)}
                            aria-sort={sortKey === col.key ? (sortDir === 'asc' ? 'ascending' : 'descending') : undefined}
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
                  {data.map((row) => (
                    <tr key={getRowId(row)}>
                      {columns.map((col) => (
                        <td key={col.key}>{col.render(row)}</td>
                      ))}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <div className={styles.mobileList}>
              {data.map((row) => (
                <div key={getRowId(row)} className={styles.mobileCard}>
                  {columns.map((col) => (
                    <div key={col.key}>
                      {(col.renderMobile ?? col.render)(row)}
                    </div>
                  ))}
                </div>
              ))}
            </div>
          </>
        ) : (
          <div className={styles.empty}>{emptyMessage}</div>
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
