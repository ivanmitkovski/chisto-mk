'use client';

import { useLayoutEffect } from 'react';
import {
  ADMIN_REDUCED_MOTION_CLASS,
  getReducedMotionPreference,
  setReducedMotionCookie,
} from '@/lib/preferences/admin-preferences';

type ReducedMotionSyncProps = {
  /** Value from the SSR cookie — must match the class on `<html>`. */
  serverReducedMotion: boolean;
};

/**
 * Syncs localStorage → cookie + DOM class after hydration (legacy users who only had localStorage).
 * Does not change React-managed `<html className>`; uses suppressHydrationWarning on `<html>` when needed.
 */
export function ReducedMotionSync({ serverReducedMotion }: ReducedMotionSyncProps) {
  useLayoutEffect(() => {
    const fromStorage = getReducedMotionPreference();
    if (fromStorage !== serverReducedMotion) {
      setReducedMotionCookie(fromStorage);
    }
    document.documentElement.classList.toggle(ADMIN_REDUCED_MOTION_CLASS, fromStorage);
  }, [serverReducedMotion]);

  return null;
}
