import type { ReactNode } from 'react';
import styles from './page-header.module.css';

export type PageHeaderProps = {
  kicker?: string;
  title: string;
  description?: string;
  /** Emphasize description (e.g. items needing attention). */
  descriptionAttention?: boolean;
  actions?: ReactNode;
  titleId?: string;
  className?: string;
};

export function PageHeader({
  kicker,
  title,
  description,
  descriptionAttention,
  actions,
  titleId,
  className,
}: PageHeaderProps) {
  const rootClass = [styles.root, className].filter(Boolean).join(' ');
  const descClass = [styles.description, descriptionAttention ? styles.descriptionAttention : '']
    .join(' ')
    .trim();
  return (
    <header className={rootClass}>
      <div className={styles.main}>
        {kicker ? <span className={styles.kicker}>{kicker}</span> : null}
        <h2 id={titleId} className={styles.title}>
          {title}
        </h2>
        {description ? <p className={descClass}>{description}</p> : null}
      </div>
      {actions ? <div className={styles.actions}>{actions}</div> : null}
    </header>
  );
}
