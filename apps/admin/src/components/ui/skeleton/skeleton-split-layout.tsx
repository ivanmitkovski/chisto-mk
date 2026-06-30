import type { ReactNode } from 'react';
import styles from './skeleton.module.css';

type SkeletonSplitLayoutProps = {
  queue: ReactNode;
  detail: ReactNode;
  queueWidth?: string;
};

export function SkeletonSplitLayout({
  queue,
  detail,
  queueWidth = 'minmax(16rem, 22rem)',
}: SkeletonSplitLayoutProps) {
  return (
    <div
      className={styles.splitLayout}
      style={{ gridTemplateColumns: `${queueWidth} minmax(0, 1fr)` }}
      aria-hidden
    >
      <aside className={styles.splitQueue}>{queue}</aside>
      <div className={styles.splitDetail}>{detail}</div>
    </div>
  );
}
