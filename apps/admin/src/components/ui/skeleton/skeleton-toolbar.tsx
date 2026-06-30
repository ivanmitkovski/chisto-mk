import styles from './skeleton.module.css';

type SkeletonToolbarProps = {
  pills?: number;
  className?: string;
};

export function SkeletonToolbar({ pills = 4, className }: SkeletonToolbarProps) {
  const rootClass = [styles.toolbarSkeleton, className].filter(Boolean).join(' ');
  return (
    <div className={rootClass} aria-hidden>
      {Array.from({ length: pills }).map((_, i) => (
        <span key={i} className={styles.toolbarPill} />
      ))}
      <span className={styles.toolbarButton} />
    </div>
  );
}
