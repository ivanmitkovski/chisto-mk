import type { ReactNode } from 'react';
import { Badge, type BadgeTone } from '../badge';
import styles from './tag.module.css';

type TagTone = BadgeTone;

export function Tag({ children, tone = 'neutral' }: { children: ReactNode; tone?: TagTone }) {
  return (
    <Badge tone={tone} className={styles.bold}>
      {children}
    </Badge>
  );
}
