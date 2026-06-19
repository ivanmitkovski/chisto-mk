import { SkeletonPageHeader } from '../skeleton-page-header';
import styles from '../skeleton.module.css';

export function BroadcastsSkeleton() {
  return (
    <div className={styles.pageStack}>
      <SkeletonPageHeader />
      <div className={styles.formCardSkeleton} aria-hidden>
        <span className={`${styles.shimmerBlock} ${styles.bar} ${styles.formCardTitle}`} />
        {Array.from({ length: 4 }).map((_, i) => (
          <span key={i} className={`${styles.shimmerBlock} ${styles.formField}`} />
        ))}
        <span className={`${styles.shimmerBlock} ${styles.toolbarButton}`} />
      </div>
      <div className={styles.campaignStack} aria-hidden>
        {Array.from({ length: 3 }).map((_, i) => (
          <span key={i} className={`${styles.shimmerBlock} ${styles.campaignCard}`} />
        ))}
      </div>
    </div>
  );
}
