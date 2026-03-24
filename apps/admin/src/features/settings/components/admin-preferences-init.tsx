'use client';

import { useEffect } from 'react';

const STORAGE_KEY = 'chisto.admin.ui.reducedMotion';
export const ADMIN_REDUCED_MOTION_CLASS = 'chisto-admin-reduced-motion';

/** Apply saved UI preferences before paint where possible (dashboard shell). */
export function AdminPreferencesInit() {
  useEffect(() => {
    try {
      if (typeof window === 'undefined') return;
      if (window.localStorage.getItem(STORAGE_KEY) === '1') {
        document.documentElement.classList.add(ADMIN_REDUCED_MOTION_CLASS);
      }
    } catch {
      /* ignore */
    }
  }, []);
  return null;
}
