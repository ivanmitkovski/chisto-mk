import { SkeletonPageHeader } from '../skeleton-page-header';
import { SkeletonTable } from '../skeleton-table';
import { SkeletonToolbar } from '../skeleton-toolbar';
import styles from '../skeleton.module.css';

export function TeamSkeleton() {
  return (
    <>
      <SkeletonPageHeader />
      <SkeletonToolbar pills={1} />
      <section className={styles.teamSection} aria-busy="true">
        <span className={`${styles.shimmerBlock} ${styles.sectionTitleBar}`} />
        <SkeletonTable rows={6} cols={4} />
      </section>
      <section className={styles.teamSection} aria-busy="true">
        <span className={`${styles.shimmerBlock} ${styles.sectionTitleBar}`} />
        <SkeletonTable rows={4} cols={5} />
      </section>
    </>
  );
}
