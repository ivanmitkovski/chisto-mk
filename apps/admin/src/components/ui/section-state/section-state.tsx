import type { ReactNode } from 'react';

import { Spinner } from '../spinner';
import styles from './section-state.module.css';

type SectionStateVariant = 'loading' | 'empty' | 'error';

type SectionStateProps = {
  variant: SectionStateVariant;
  message: string;
  /** Optional actions (e.g. refresh) shown below the message. */
  children?: ReactNode;
};

export function SectionState({ variant, message, children }: SectionStateProps) {
  const className = [
    styles.state,
    variant === 'loading' ? styles.loading : '',
    variant === 'error' ? styles.error : '',
  ]
    .join(' ')
    .trim();

  return (
    <div className={className} role="status" aria-live="polite">
      {variant === 'loading' && (
        <Spinner size="md" className={styles.spinner} />
      )}
      <span className={styles.message}>{message}</span>
      {children ? <div className={styles.actions}>{children}</div> : null}
    </div>
  );
}
