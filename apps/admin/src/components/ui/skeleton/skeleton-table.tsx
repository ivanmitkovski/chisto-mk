import styles from './skeleton.module.css';

type SkeletonTableProps = {
  rows?: number;
  cols?: number;
};

const CELL_BAR_WIDTHS = [
  styles.tableCellBarWide,
  styles.tableCellBarMedium,
  styles.tableCellBarNarrow,
] as const;

function tableCellBarClass(colIndex: number): string {
  return CELL_BAR_WIDTHS[colIndex % CELL_BAR_WIDTHS.length];
}

export function SkeletonTable({ rows = 5, cols = 4 }: SkeletonTableProps) {
  return (
    <div className={styles.tableWrap}>
      <table className={styles.table}>
        <thead>
          <tr>
            {Array.from({ length: cols }).map((_, i) => (
              <th key={i}>
                <span className={`${styles.shimmerBlock} ${styles.tableCellBar} ${tableCellBarClass(i)}`} />
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {Array.from({ length: rows }).map((_, rowIndex) => (
            <tr key={rowIndex}>
              {Array.from({ length: cols }).map((_, colIndex) => (
                <td key={colIndex}>
                  <span
                    className={`${styles.shimmerBlock} ${styles.tableCellBar} ${tableCellBarClass(colIndex)}`}
                  />
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
