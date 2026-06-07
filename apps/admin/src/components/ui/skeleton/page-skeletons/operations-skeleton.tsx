import { SkeletonPageHeader } from '../skeleton-page-header';
import styles from '../skeleton.module.css';

export function OperationsSkeleton() {
  return (
    <>
      <SkeletonPageHeader />
      <div className={styles.operationsToolbar} aria-hidden>
        {Array.from({ length: 3 }).map((_, i) => (
          <span key={i} className={`${styles.shimmerBlock} ${styles.toolbarPill}`} />
        ))}
      </div>
      <div className={styles.linkRowSkeleton} aria-hidden>
        <span className={`${styles.shimmerBlock} ${styles.linkBar}`} />
        <span className={`${styles.shimmerBlock} ${styles.linkBar}`} />
      </div>
      <div className={styles.metricGrid} aria-hidden>
        {Array.from({ length: 8 }).map((_, i) => (
          <span key={i} className={`${styles.shimmerBlock} ${styles.metricCard}`} />
        ))}
      </div>
    </>
  );
}
