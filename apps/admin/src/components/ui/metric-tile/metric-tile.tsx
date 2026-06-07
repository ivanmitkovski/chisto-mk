import type { ReactNode } from 'react';
import type { IconName } from '../icon';
import { Icon } from '../icon';
import styles from './metric-tile.module.css';

export type MetricTileTone = 'neutral' | 'success' | 'warning' | 'danger';

export type MetricTileProps = {
  label: string;
  value: ReactNode;
  delta?: string;
  tone?: MetricTileTone;
  icon?: IconName;
  sparkline?: ReactNode;
  href?: string;
};

export function MetricTile({
  label,
  value,
  delta,
  tone = 'neutral',
  icon,
  sparkline,
  href,
}: MetricTileProps) {
  const content = (
    <>
      <div className={styles.header}>
        {icon ? (
          <span className={styles.icon} aria-hidden>
            <Icon name={icon} size={16} />
          </span>
        ) : null}
        <dt className={styles.label}>{label}</dt>
      </div>
      <dd className={`${styles.value} ${styles[`tone_${tone}`]}`}>{value}</dd>
      {delta ? <p className={styles.delta}>{delta}</p> : null}
      {sparkline ? <div className={styles.sparkline}>{sparkline}</div> : null}
    </>
  );

  if (href) {
    return (
      <a href={href} className={styles.tile}>
        {content}
      </a>
    );
  }

  return <div className={styles.tile}>{content}</div>;
}

export function MetricTileGrid({ children }: { children: ReactNode }) {
  return <dl className={styles.grid}>{children}</dl>;
}
