import styles from './progress-bar.module.css';

export function ProgressBar({
  value,
  max = 100,
  label,
}: {
  value: number;
  max?: number;
  label?: string;
}) {
  const clamped = Math.min(max, Math.max(0, value));
  return (
    <div className={styles.root}>
      <progress className={styles.progress} aria-label={label} max={max} value={clamped} />
      {label ? <span>{label}</span> : null}
    </div>
  );
}
