import styles from './skeleton.module.css';

type SkeletonListItemProps = {
  showIcon?: boolean;
  lines?: number;
};

export function SkeletonListItem({ showIcon = true, lines = 2 }: SkeletonListItemProps) {
  return (
    <div className={styles.listItem} aria-hidden>
      {showIcon ? <span className={`${styles.shimmerBlock} ${styles.listItemIcon}`} /> : null}
      <div className={styles.listItemText}>
        {Array.from({ length: lines }).map((_, i) => (
          <span
            key={i}
            className={`${styles.shimmerBlock} ${styles.bar} ${i === 0 ? styles.listItemTitle : styles.listItemBody}`}
          />
        ))}
      </div>
    </div>
  );
}
