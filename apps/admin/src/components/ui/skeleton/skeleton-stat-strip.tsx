import styles from './skeleton.module.css';

type SkeletonStatStripProps = {
  count?: number;
  className?: string;
};

export function SkeletonStatStrip({ count = 4, className }: SkeletonStatStripProps) {
  return (
    <div
      className={[styles.statStrip, className].filter(Boolean).join(' ')}
      aria-hidden
    >
      {Array.from({ length: count }).map((_, i) => (
        <span key={i} className={styles.statPill} />
      ))}
    </div>
  );
}
