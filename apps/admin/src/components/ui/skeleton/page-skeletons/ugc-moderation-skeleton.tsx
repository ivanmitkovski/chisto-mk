import { SkeletonListItem } from '../skeleton-list-item';
import { SkeletonPageHeader } from '../skeleton-page-header';
import { SkeletonSplitLayout } from '../skeleton-split-layout';
import styles from '../skeleton.module.css';

export function UgcModerationSkeleton() {
  return (
    <>
      <SkeletonPageHeader />
      <SkeletonSplitLayout
        queue={
          <>
            <span className={`${styles.shimmerBlock} ${styles.sectionLabelBar}`} />
            {Array.from({ length: 5 }).map((_, i) => (
              <SkeletonListItem key={i} />
            ))}
          </>
        }
        detail={
          <>
            <span className={`${styles.shimmerBlock} ${styles.splitBlock}`} />
            <span className={`${styles.shimmerBlock} ${styles.splitBlock} ${styles.splitBlockTall}`} />
            <div className={styles.detailActionsRow} aria-hidden>
              {Array.from({ length: 5 }).map((_, i) => (
                <span key={i} className={`${styles.shimmerBlock} ${styles.detailActionPill}`} />
              ))}
            </div>
          </>
        }
      />
    </>
  );
}
