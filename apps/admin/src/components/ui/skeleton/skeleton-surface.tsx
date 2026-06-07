'use client';

import type { ReactNode } from 'react';
import styles from './skeleton.module.css';

type SkeletonSurfaceProps = {
  children: ReactNode;
};

/** Wraps route-level skeletons with a soft enter animation and stable shimmer root. */
export function SkeletonSurface({ children }: SkeletonSurfaceProps) {
  return (
    <div className={styles.skeletonSurface} aria-busy="true" role="status" aria-live="polite">
      {children}
    </div>
  );
}
