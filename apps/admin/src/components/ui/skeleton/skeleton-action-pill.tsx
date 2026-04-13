import styles from './skeleton.module.css';

type SkeletonActionPillProps = {
  className?: string;
};

export function SkeletonActionPill({ className }: SkeletonActionPillProps) {
  const rootClass = [styles.actionPill, className].filter(Boolean).join(' ');
  return <span className={rootClass} aria-hidden />;
}
