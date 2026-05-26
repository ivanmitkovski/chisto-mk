import styles from './reports-trend-chart-skeleton.module.css';

type ReportsTrendChartSkeletonProps = {
  height?: number;
};

export function ReportsTrendChartSkeleton({ height = 120 }: ReportsTrendChartSkeletonProps) {
  const sizeClass = height >= 160 ? styles.tall : height <= 96 ? styles.compact : styles.defaultHeight;
  return (
    <div className={`${styles.root} ${sizeClass}`} aria-hidden>
      <div className={styles.bar} />
      <div className={styles.bar} />
      <div className={styles.bar} />
      <div className={styles.bar} />
      <div className={styles.bar} />
      <div className={styles.bar} />
      <div className={styles.bar} />
    </div>
  );
}
