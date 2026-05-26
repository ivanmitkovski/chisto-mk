import type { ReactNode } from 'react';
import styles from './tag.module.css';

type TagTone = 'neutral' | 'success' | 'warning' | 'danger' | 'info';

export function Tag({ children, tone = 'neutral' }: { children: ReactNode; tone?: TagTone }) {
  return <span className={`${styles.tag} ${styles[tone]}`}>{children}</span>;
}
