import { ReactNode } from 'react';
import styles from './tooltip.module.css';

type TooltipProps = {
  label: string;
  children: ReactNode;
};

export function Tooltip({ label, children }: TooltipProps) {
  return (
    <span className={styles.root}>
      {children}
      <span className={styles.bubble} role="tooltip">
        {label}
      </span>
    </span>
  );
}
