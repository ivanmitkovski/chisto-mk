import type { ReactNode } from 'react';
import { Icon, type IconName } from '../icon';
import styles from './empty-state.module.css';

export type EmptyStateProps = {
  title: string;
  description?: string;
  icon?: IconName;
  action?: ReactNode;
  className?: string;
};

export function EmptyState({ title, description, icon, action, className }: EmptyStateProps) {
  const rootClassName = [styles.root, className ?? ''].join(' ').trim();

  return (
    <div className={rootClassName} role="status">
      {icon ? (
        <span className={styles.iconWrap} aria-hidden>
          <Icon name={icon} size={22} />
        </span>
      ) : null}
      <h3 className={styles.title}>{title}</h3>
      {description ? <p className={styles.description}>{description}</p> : null}
      {action ? <div className={styles.action}>{action}</div> : null}
    </div>
  );
}
