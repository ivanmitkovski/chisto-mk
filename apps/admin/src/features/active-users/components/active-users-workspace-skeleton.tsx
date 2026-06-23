import { SkeletonTable } from '@/components/ui';
import styles from './active-users-workspace-skeleton.module.css';

export function ActiveUsersWorkspaceSkeleton() {
  return (
    <section className={styles.root} aria-busy="true">
      <div className={styles.header}>
        <span className={`${styles.shimmer} ${styles.titleBar}`} />
        <span className={`${styles.shimmer} ${styles.descBar}`} />
      </div>
      <div className={styles.toolbar}>
        <span className={`${styles.shimmer} ${styles.searchBar}`} />
        {Array.from({ length: 4 }).map((_, i) => (
          <span key={i} className={`${styles.shimmer} ${styles.chipBar}`} />
        ))}
        <span className={`${styles.shimmer} ${styles.selectBar}`} />
      </div>
      <div className={styles.layout}>
        <div className={styles.main}>
          <div className={styles.kpiGrid}>
            {Array.from({ length: 7 }).map((_, i) => (
              <span key={i} className={`${styles.shimmer} ${styles.kpiCard}`} />
            ))}
          </div>
          <div className={styles.chartRow}>
            <span className={`${styles.shimmer} ${styles.chartCard}`} />
            <span className={`${styles.shimmer} ${styles.chartCard}`} />
          </div>
          <span className={`${styles.shimmer} ${styles.sectionLabel}`} />
          <SkeletonTable rows={8} cols={7} />
        </div>
        <aside className={styles.side}>
          <span className={`${styles.shimmer} ${styles.sideCard}`} />
          <span className={`${styles.shimmer} ${styles.mapCard}`} />
          <span className={`${styles.shimmer} ${styles.sideCard}`} />
        </aside>
      </div>
    </section>
  );
}
