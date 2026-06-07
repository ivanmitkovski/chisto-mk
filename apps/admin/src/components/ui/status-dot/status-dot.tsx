import styles from './status-dot.module.css';

export type HealthStatus = 'ok' | 'warn' | 'critical' | 'unknown';

export type StatusDotProps = {
  status: HealthStatus;
  label: string;
  className?: string;
};

export function StatusDot({ status, label, className }: StatusDotProps) {
  return (
    <span className={[styles.wrap, className].filter(Boolean).join(' ')} role="status">
      <span className={`${styles.dot} ${styles[status]}`} aria-hidden />
      <span className={styles.label}>{label}</span>
    </span>
  );
}
