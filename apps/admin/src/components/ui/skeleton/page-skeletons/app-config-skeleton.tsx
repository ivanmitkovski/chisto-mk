import { SkeletonPageHeader } from '../skeleton-page-header';
import styles from '../skeleton.module.css';

export function AppConfigSkeleton() {
  return (
    <>
      <SkeletonPageHeader />
      <div className={styles.configStack} aria-hidden>
        {Array.from({ length: 4 }).map((_, i) => (
          <div key={i} className={styles.configSectionCard}>
            <span className={`${styles.shimmerBlock} ${styles.bar} ${styles.formCardTitle}`} />
            {Array.from({ length: 3 }).map((_, j) => (
              <span key={j} className={`${styles.shimmerBlock} ${styles.formField}`} />
            ))}
            <span className={`${styles.shimmerBlock} ${styles.toolbarButton}`} />
          </div>
        ))}
      </div>
    </>
  );
}
