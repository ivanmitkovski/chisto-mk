'use client';

import { useId, useState, type ReactNode } from 'react';
import styles from './tooltip.module.css';

type TooltipProps = {
  label: string;
  children: ReactNode;
};

export function Tooltip({ label, children }: TooltipProps) {
  const id = useId();
  const [open, setOpen] = useState(false);

  return (
    <span className={styles.root}>
      <span
        tabIndex={0}
        className={styles.trigger}
        aria-describedby={open ? id : undefined}
        onMouseEnter={() => setOpen(true)}
        onMouseLeave={() => setOpen(false)}
        onFocus={() => setOpen(true)}
        onBlur={() => setOpen(false)}
      >
        {children}
      </span>
      {open ? (
        <span id={id} className={styles.bubble} role="tooltip">
          {label}
        </span>
      ) : null}
    </span>
  );
}
