import type { ReactNode } from 'react';

import { Spinner } from '../spinner';
import { PanelSkeleton } from '../skeleton';
import styles from './section-state.module.css';

type SectionStateVariant = 'loading' | 'loading-skeleton' | 'empty' | 'error';

type SectionStateProps = {
  variant: SectionStateVariant;
  message: string;
  /** Optional actions (e.g. refresh) shown below the message. */
  children?: ReactNode;
  /** Skeleton lines when variant is loading-skeleton (default 3). */
  skeletonLines?: number;
};

export function SectionState({
  variant,
  message,
  children,
  skeletonLines = 3,
}: SectionStateProps) {
  const className = [
    styles.state,
    variant === 'loading' || variant === 'loading-skeleton' ? styles.loading : '',
    variant === 'error' ? styles.error : '',
  ]
    .join(' ')
    .trim();

  const isError = variant === 'error';

  return (
    <div
      className={className}
      role={isError ? 'alert' : 'status'}
      aria-live={isError ? 'assertive' : 'polite'}
      aria-atomic={isError ? true : undefined}
    >
      {variant === 'loading' && <Spinner size="md" className={styles.spinner} />}
      {variant === 'loading-skeleton' ? (
        <PanelSkeleton lines={skeletonLines} />
      ) : null}
      <span className={styles.message}>{message}</span>
      {children ? <div className={styles.actions}>{children}</div> : null}
    </div>
  );
}
