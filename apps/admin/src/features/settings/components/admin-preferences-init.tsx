'use client';

import { useEffect } from 'react';
import {
  ADMIN_REDUCED_MOTION_CLASS,
  getReducedMotionPreference,
} from '@/lib/admin-preferences';

export { ADMIN_REDUCED_MOTION_CLASS } from '@/lib/admin-preferences';

/** Apply saved UI preferences before paint where possible (dashboard shell). */
export function AdminPreferencesInit() {
  useEffect(() => {
    try {
      if (typeof window === 'undefined') return;
      if (getReducedMotionPreference()) {
        document.documentElement.classList.add(ADMIN_REDUCED_MOTION_CLASS);
      }
    } catch {
      /* ignore */
    }
  }, []);
  return null;
}
