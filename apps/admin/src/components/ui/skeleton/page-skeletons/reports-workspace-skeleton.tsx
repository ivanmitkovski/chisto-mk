import { SkeletonTable } from '../skeleton-table';
import styles from '../skeleton.module.css';

/** Full reports list page skeleton (summary, queue, filters, table). */
export function ReportsWorkspaceSkeleton() {
  return (
    <section className={styles.reportsWorkspace} aria-busy="true">
      <div className={styles.summaryStripSkeleton}>
        {Array.from({ length: 3 }).map((_, i) => (
          <span key={i} className={`${styles.shimmerBlock} ${styles.summaryBar}`} />
        ))}
      </div>
      <span className={`${styles.shimmerBlock} ${styles.sectionLabelBar}`} />
      <div className={styles.reportsHeaderSkeleton}>
        <div className={styles.reportsHeaderText}>
          <span className={`${styles.shimmerBlock} ${styles.bar} ${styles.reportsTitleBar}`} />
          <span className={`${styles.shimmerBlock} ${styles.bar} ${styles.reportsSubtitleBar}`} />
        </div>
      </div>
      <div className={styles.reportsToolbarSkeleton} aria-hidden>
        <span className={`${styles.shimmerBlock} ${styles.searchBar}`} />
        <div className={styles.filterChipsRow}>
          {Array.from({ length: 5 }).map((_, i) => (
            <span key={i} className={`${styles.shimmerBlock} ${styles.filterChip}`} />
          ))}
        </div>
      </div>
      <SkeletonTable rows={8} cols={5} />
    </section>
  );
}
