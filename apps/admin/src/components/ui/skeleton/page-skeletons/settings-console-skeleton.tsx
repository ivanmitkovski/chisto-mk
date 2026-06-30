import { SkeletonCard } from '../skeleton-card';
import styles from '../skeleton.module.css';

const NAV_ITEM_COUNT = 6;

export function SettingsConsoleSkeleton() {
  return (
    <div className={styles.settingsLayout}>
      <nav className={styles.settingsNav} aria-hidden>
        {Array.from({ length: NAV_ITEM_COUNT }).map((_, i) => (
          <span key={i} className={`${styles.shimmerBlock} ${styles.settingsNavItem}`} />
        ))}
      </nav>
      <div className={styles.settingsPanel}>
        <SkeletonCard lines={2} />
        <SkeletonCard lines={5} />
      </div>
    </div>
  );
}
