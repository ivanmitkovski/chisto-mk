import styles from './skeleton.module.css';

type SkeletonPageHeaderProps = {
  showActions?: boolean;
  className?: string;
};

export function SkeletonPageHeader({ showActions = true, className }: SkeletonPageHeaderProps) {
  const rootClass = [styles.pageHeaderSkeleton, className].filter(Boolean).join(' ');
  return (
    <div className={rootClass} aria-hidden>
      <div className={styles.pageHeaderText}>
        <span className={styles.pageHeaderKicker} />
        <span className={styles.pageHeaderTitle} />
        <span className={styles.pageHeaderDesc} />
      </div>
      {showActions ? <span className={styles.pageHeaderActions} /> : null}
    </div>
  );
}
