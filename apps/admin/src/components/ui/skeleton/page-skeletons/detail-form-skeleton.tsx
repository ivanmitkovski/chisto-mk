import { SkeletonCard } from '../skeleton-card';
import { SkeletonPageHeader } from '../skeleton-page-header';
import styles from '../skeleton.module.css';

export function DetailFormSkeleton() {
  return (
    <>
      <span className={`${styles.shimmerBlock} ${styles.backLink}`} aria-hidden />
      <SkeletonPageHeader />
      <SkeletonCard lines={8} />
    </>
  );
}
