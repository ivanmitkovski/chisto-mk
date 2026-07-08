'use client';

import { useEffect, useState } from 'react';

/** Online status for draft autosave / offline banner. Always starts online to match SSR. */
export function useNewsOnlineStatus(): boolean {
  const [online, setOnline] = useState(true);

  useEffect(() => {
    const sync = () => setOnline(navigator.onLine);
    sync();
    window.addEventListener('online', sync);
    window.addEventListener('offline', sync);
    return () => {
      window.removeEventListener('online', sync);
      window.removeEventListener('offline', sync);
    };
  }, []);

  return online;
}
