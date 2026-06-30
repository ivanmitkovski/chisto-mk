import { HTMLAttributes, ReactNode } from 'react';
import styles from './badge.module.css';

export type BadgeTone = 'neutral' | 'success' | 'warning' | 'danger' | 'info';

type BadgeProps = HTMLAttributes<HTMLSpanElement> & {
  tone?: BadgeTone;
  children: ReactNode;
};

export function Badge({ tone = 'neutral', className, children, ...rest }: BadgeProps) {
  return (
    <span className={[styles.badge, styles[tone], className ?? ''].join(' ').trim()} {...rest}>
      {children}
    </span>
  );
}
