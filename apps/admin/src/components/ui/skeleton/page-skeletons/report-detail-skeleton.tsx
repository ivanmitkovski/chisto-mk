import styles from '../skeleton.module.css';

/** Report detail two-column layout skeleton (matches report review page). */
export function ReportDetailSkeleton() {
  return (
    <div className={styles.reportDetailPage}>
      <div className={styles.reportDetailHeader}>
        <span className={`${styles.shimmerBlock} ${styles.backLink}`} />
        <span className={`${styles.shimmerBlock} ${styles.reportDetailTitle}`} />
        <div className={styles.headerPillsRow} aria-hidden>
          {Array.from({ length: 3 }).map((_, i) => (
            <span key={i} className={`${styles.shimmerBlock} ${styles.headerPill}`} />
          ))}
        </div>
      </div>
      <div className={styles.reportDetailGrid}>
        <span className={`${styles.shimmerBlock} ${styles.reportDetailMain}`} />
        <span className={`${styles.shimmerBlock} ${styles.reportDetailRail}`} />
      </div>
    </div>
  );
}
