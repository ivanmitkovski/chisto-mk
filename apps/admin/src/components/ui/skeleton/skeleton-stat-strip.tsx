import styles from './skeleton.module.css';

type SkeletonStatStripProps = {
  count?: number;
  className?: string;
};

export function SkeletonStatStrip({ count = 5, className }: SkeletonStatStripProps) {
  const rootClass = [styles.statStrip, className].filter(Boolean).join(' ');
  return (
    <div className={rootClass} aria-hidden>
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className={styles.statStripCard}>
          <span className={styles.statStripIcon} />
          <span className={styles.statStripValue} />
          <span className={styles.statStripLabel} />
        </div>
      ))}
    </div>
  );
}
