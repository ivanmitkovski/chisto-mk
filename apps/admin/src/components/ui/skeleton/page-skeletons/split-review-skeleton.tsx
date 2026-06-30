import { SkeletonListItem } from '../skeleton-list-item';
import { SkeletonSplitLayout } from '../skeleton-split-layout';
import styles from '../skeleton.module.css';

type SplitReviewSkeletonProps = {
  queueItems?: number;
};

export function SplitReviewSkeleton({ queueItems = 5 }: SplitReviewSkeletonProps) {
  return (
    <SkeletonSplitLayout
      queue={
        <>
          <span className={`${styles.shimmerBlock} ${styles.sectionLabel}`} />
          {Array.from({ length: queueItems }).map((_, i) => (
            <SkeletonListItem key={i} />
          ))}
        </>
      }
      detail={
        <>
          <span className={`${styles.shimmerBlock} ${styles.splitBlock}`} />
          <span className={`${styles.shimmerBlock} ${styles.splitBlock} ${styles.splitBlockTall}`} />
        </>
      }
    />
  );
}
