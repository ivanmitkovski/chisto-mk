import styles from './reports-trend-chart-skeleton.module.css';

type ReportsTrendChartSkeletonProps = {
  height?: number;
};

export function ReportsTrendChartSkeleton({ height = 120 }: ReportsTrendChartSkeletonProps) {
  return (
    <div className={styles.root} style={{ height }} aria-hidden>
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
