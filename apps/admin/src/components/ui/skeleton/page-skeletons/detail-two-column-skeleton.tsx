import { SkeletonCard } from '../skeleton-card';
import styles from '../skeleton.module.css';

export function DetailTwoColumnSkeleton() {
  return (
    <div className={styles.twoColumn}>
      <SkeletonCard lines={5} />
      <SkeletonCard lines={4} />
    </div>
  );
}
