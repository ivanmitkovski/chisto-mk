import { SkeletonCard } from '../skeleton-card';
import { SkeletonPageHeader } from '../skeleton-page-header';
import styles from '../skeleton.module.css';

export function DetailMultiSectionSkeleton() {
  return (
    <>
      <span className={`${styles.shimmerBlock} ${styles.backLink}`} aria-hidden />
      <SkeletonPageHeader />
      <div className={styles.insightsSectionSkeleton} aria-hidden>
        <span className={`${styles.shimmerBlock} ${styles.sectionLabelBar}`} />
        <div className={styles.insightsBarRow}>
          {Array.from({ length: 4 }).map((_, i) => (
            <span key={i} className={`${styles.shimmerBlock} ${styles.insightsBar}`} />
          ))}
        </div>
      </div>
      <SkeletonCard lines={2} />
      <div className={styles.moderationSectionSkeleton} aria-hidden>
        <span className={`${styles.shimmerBlock} ${styles.sectionLabelBar}`} />
        <div className={styles.moderationBarRow}>
          {Array.from({ length: 3 }).map((_, i) => (
            <span key={i} className={`${styles.shimmerBlock} ${styles.moderationBar}`} />
          ))}
        </div>
      </div>
      <SkeletonCard lines={6} />
      <SkeletonCard lines={4} />
    </>
  );
}
