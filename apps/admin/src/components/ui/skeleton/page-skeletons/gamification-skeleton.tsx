import { SkeletonCard } from '../skeleton-card';
import { SkeletonPageHeader } from '../skeleton-page-header';
import styles from '../skeleton.module.css';

export function GamificationSkeleton() {
  return (
    <>
      <SkeletonPageHeader />
      <div className={styles.tabsRow} aria-hidden>
        <span className={`${styles.shimmerBlock} ${styles.tabPill}`} />
        <span className={`${styles.shimmerBlock} ${styles.tabPill}`} />
      </div>
      <SkeletonCard lines={6} />
    </>
  );
}
