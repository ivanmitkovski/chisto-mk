import { SkeletonCard } from '../skeleton-card';
import { SkeletonTable } from '../skeleton-table';
import styles from '../skeleton.module.css';

export function OverviewStatsSkeleton() {
  return (
    <div className={styles.overviewStats} aria-hidden>
      {Array.from({ length: 4 }).map((_, i) => (
        <span key={i} className={`${styles.shimmerBlock} ${styles.overviewStat}`} />
      ))}
    </div>
  );
}

export function OverviewSkeleton() {
  return (
    <div className={styles.pageStack}>
      <header className={styles.overviewTopBar} aria-hidden>
        <OverviewStatsSkeleton />
        <span className={`${styles.shimmerBlock} ${styles.actionPill}`} />
      </header>

      <section className={styles.overviewReportsSection} aria-busy="true">
        <div className={styles.summaryStripSkeleton}>
          {Array.from({ length: 3 }).map((_, i) => (
            <span key={i} className={`${styles.shimmerBlock} ${styles.summaryBar}`} />
          ))}
        </div>
        <span className={`${styles.shimmerBlock} ${styles.sectionLabelBar}`} />
        <div className={styles.reportsHeaderSkeleton}>
          <span className={`${styles.shimmerBlock} ${styles.bar} ${styles.reportsTitleBar}`} />
          <span className={`${styles.shimmerBlock} ${styles.toolbarPill}`} />
        </div>
        <div className={styles.filterChipsRow} aria-hidden>
          {Array.from({ length: 5 }).map((_, i) => (
            <span key={i} className={`${styles.shimmerBlock} ${styles.filterChip}`} />
          ))}
        </div>
        <SkeletonTable rows={5} cols={5} />
      </section>

      <section className={styles.overviewInsightsSection} aria-busy="true">
        <span className={`${styles.shimmerBlock} ${styles.bar} ${styles.insightsHeadingBar}`} />
        <div className={styles.insightsRow}>
          {Array.from({ length: 4 }).map((_, i) => (
            <SkeletonCard key={i} lines={i === 1 ? 4 : 3} />
          ))}
        </div>
      </section>
    </div>
  );
}
