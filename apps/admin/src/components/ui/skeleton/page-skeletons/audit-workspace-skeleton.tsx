import { SkeletonStatStrip } from '../skeleton-stat-strip';
import { SkeletonTable } from '../skeleton-table';
import styles from '../skeleton.module.css';

export function AuditWorkspaceSkeleton() {
  return (
    <>
      <SkeletonStatStrip count={2} />
      <div className={styles.auditFiltersCard} aria-hidden>
        <span className={`${styles.shimmerBlock} ${styles.sectionLabelBar}`} />
        <div className={styles.filterGrid}>
          {Array.from({ length: 5 }).map((_, i) => (
            <span key={i} className={`${styles.shimmerBlock} ${styles.formField}`} />
          ))}
        </div>
        <div className={styles.filterActionsRow}>
          <span className={`${styles.shimmerBlock} ${styles.toolbarButton}`} />
          <span className={`${styles.shimmerBlock} ${styles.toolbarPill}`} />
        </div>
      </div>
      <SkeletonTable rows={10} cols={5} />
    </>
  );
}
