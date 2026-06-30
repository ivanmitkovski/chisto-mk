import { SkeletonTable } from '../skeleton-table';
import styles from '../skeleton.module.css';

export function RiskSignalsSkeleton() {
  return (
    <div className={styles.pageStack}>
      <span className={`${styles.shimmerBlock} ${styles.introLine}`} aria-hidden />
      <span className={`${styles.shimmerBlock} ${styles.backLinkBar}`} aria-hidden />
      <span className={`${styles.shimmerBlock} ${styles.statusSelectPill}`} aria-hidden />
      <SkeletonTable rows={8} cols={7} />
    </div>
  );
}
