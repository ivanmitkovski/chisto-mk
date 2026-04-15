import type { HTMLAttributes, ReactNode } from 'react';
import styles from './content-card.module.css';

export type ContentCardProps = {
  children: ReactNode;
  className?: string;
  padding?: 'sm' | 'md';
} & Omit<HTMLAttributes<HTMLDivElement>, 'className' | 'children'>;

const paddingClass: Record<NonNullable<ContentCardProps['padding']>, string> = {
  sm: styles.paddingSm,
  md: styles.paddingMd,
};

export function ContentCard({ children, className, padding = 'md', ...rest }: ContentCardProps) {
  const rootClass = [styles.root, paddingClass[padding], className].filter(Boolean).join(' ');
  return (
    <div className={rootClass} {...rest}>
      {children}
    </div>
  );
}
