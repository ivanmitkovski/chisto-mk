import type { ReactNode } from 'react';
import styles from './toolbar.module.css';

export type ToolbarProps = {
  children: ReactNode;
  /** Secondary actions (e.g. Refresh) — rendered at end on wide screens */
  end?: ReactNode;
  /** Shown on narrow viewports when filters are active (e.g. count of active filters) */
  activeFilterCount?: number;
  'aria-label'?: string;
  className?: string;
};

export function Toolbar({
  children,
  end,
  activeFilterCount,
  'aria-label': ariaLabel = 'Filters and actions',
  className,
}: ToolbarProps) {
  const rootClass = [styles.root, className].filter(Boolean).join(' ');
  return (
    <div className={rootClass} role="toolbar" aria-label={ariaLabel}>
      <div className={styles.filters}>
        {typeof activeFilterCount === 'number' && activeFilterCount > 0 ? (
          <span className={styles.badge} aria-live="polite">
            {activeFilterCount} filter{activeFilterCount === 1 ? '' : 's'}
          </span>
        ) : null}
        {children}
      </div>
      {end ? <div className={styles.end}>{end}</div> : null}
    </div>
  );
}
