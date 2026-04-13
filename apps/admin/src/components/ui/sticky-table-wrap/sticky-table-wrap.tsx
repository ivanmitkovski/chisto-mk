import type { ReactNode } from 'react';
import styles from './sticky-table-wrap.module.css';

export type StickyTableWrapProps = {
  children: ReactNode;
  className?: string;
};

export function StickyTableWrap({ children, className }: StickyTableWrapProps) {
  const rootClass = [styles.wrap, className].filter(Boolean).join(' ');
  return <div className={rootClass}>{children}</div>;
}
