import { SkeletonPageHeader } from '../skeleton-page-header';
import styles from '../skeleton.module.css';

export function OperationsSkeleton() {
  return (
    <>
      <SkeletonPageHeader />
      <span className={`${styles.shimmerBlock} ${styles.metricCard}`} aria-hidden style={{ marginBottom: 'var(--space-4)' }} />
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
      {Array.from({ length: 4 }).map((_, section) => (
        <div key={section} className={styles.metricGrid} aria-hidden style={{ marginTop: 'var(--space-6)' }}>
          {Array.from({ length: 3 }).map((__, i) => (
            <span key={`${section}-${i}`} className={`${styles.shimmerBlock} ${styles.metricCard}`} />
          ))}
        </div>
      ))}
    </>
  );
}
