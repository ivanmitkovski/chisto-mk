'use client';

import { useEffect, useState } from 'react';

/** True after the browser has hydrated — use before rendering clock-relative labels. */
export function useClientHydrated(): boolean {
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    setHydrated(true);
  }, []);

  return hydrated;
}
