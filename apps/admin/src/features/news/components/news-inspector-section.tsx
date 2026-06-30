'use client';

import type { ReactNode } from 'react';
import styles from './news-inspector.module.css';

type NewsInspectorSectionProps = {
  title: string;
  description?: string;
  defaultOpen?: boolean;
  children: ReactNode;
};

export function NewsInspectorSection({
  title,
  description,
  defaultOpen = true,
  children,
}: NewsInspectorSectionProps) {
  return (
    <details className={styles.section} open={defaultOpen || undefined}>
      <summary className={styles.sectionSummary}>{title}</summary>
      <div className={styles.sectionBody}>
        {description ? <p className={styles.sectionDescription}>{description}</p> : null}
        {children}
      </div>
    </details>
  );
}
