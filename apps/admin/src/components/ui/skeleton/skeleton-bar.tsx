import styles from './skeleton.module.css';

type SkeletonBarProps = {
  width?: string;
  height?: string;
  className?: string;
  title?: boolean;
};

export function SkeletonBar({ width, height, className, title }: SkeletonBarProps) {
  const classes = [styles.shimmerBlock, styles.bar, title ? styles.title : '', className]
    .filter(Boolean)
    .join(' ');
  return (
    <span
      className={classes}
      aria-hidden
      style={{
        ...(width ? { width } : undefined),
        ...(height ? { height } : undefined),
      }}
    />
  );
}
