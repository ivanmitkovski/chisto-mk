import { SkeletonCard } from '../skeleton-card';
import { SkeletonPageHeader } from '../skeleton-page-header';
import { SkeletonTabs } from '../skeleton-tabs';
import styles from '../skeleton.module.css';

export function DetailTabsSkeleton() {
  return (
    <>
      <SkeletonPageHeader />
      <SkeletonTabs count={5} />
      <SkeletonCard lines={6} />
      <div className={styles.twoColumn} aria-hidden>
        <SkeletonCard lines={4} />
        <SkeletonCard lines={3} />
      </div>
    </>
  );
}
