import styles from './skeleton.module.css';

type SkeletonTabsProps = {
  count?: number;
};

export function SkeletonTabs({ count = 5 }: SkeletonTabsProps) {
  return (
    <div className={styles.tabsRow} aria-hidden>
      {Array.from({ length: count }).map((_, i) => (
        <span key={i} className={`${styles.shimmerBlock} ${styles.tabPill}`} />
      ))}
    </div>
  );
}
