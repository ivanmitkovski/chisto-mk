import { SkeletonPageHeader } from '../skeleton-page-header';
import styles from '../skeleton.module.css';

export function OperationsSkeleton() {
  return (
    <div className={styles.pageStack}>
      <SkeletonPageHeader />
      <span className={`${styles.shimmerBlock} ${styles.metricCard}`} aria-hidden />
      <div className={styles.operationsToolbar} aria-hidden>
        {Array.from({ length: 3 }).map((_, i) => (
          <span key={i} className={`${styles.shimmerBlock} ${styles.toolbarPill}`} />
        ))}
      </div>
      <div className={styles.linkRowSkeleton} aria-hidden>
        <span className={`${styles.shimmerBlock} ${styles.linkBar}`} />
        <span className={`${styles.shimmerBlock} ${styles.linkBar}`} />
        <span className={`${styles.shimmerBlock} ${styles.linkBar}`} />
      </div>
      <div className={styles.cardStack} aria-hidden>
        {Array.from({ length: 4 }).map((_, section) => (
          <div key={section} className={styles.metricGrid}>
            {Array.from({ length: 3 }).map((__, i) => (
              <span key={`${section}-${i}`} className={`${styles.shimmerBlock} ${styles.metricCard}`} />
            ))}
          </div>
        ))}
      </div>
    </div>
  );
}
