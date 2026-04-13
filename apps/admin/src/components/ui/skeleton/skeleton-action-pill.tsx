import styles from './skeleton.module.css';

type SkeletonActionPillProps = {
  className?: string;
};

export function SkeletonActionPill({ className }: SkeletonActionPillProps) {
  return (
    <span
      className={[styles.actionPill, className].filter(Boolean).join(' ')}
      aria-hidden
    />
  );
}
