'use client';

import { useEffect, useRef, useState } from 'react';

/**
 * Keeps local client state in sync with server props after `router.refresh()`.
 * Uses JSON serialization for change detection (works for plain data objects/arrays).
 */
export function useServerSyncedState<T>(initialValue: T): [T, React.Dispatch<React.SetStateAction<T>>] {
  const [value, setValue] = useState(initialValue);
  const serialized = JSON.stringify(initialValue);
  const prevSerialized = useRef(serialized);

  useEffect(() => {
    if (prevSerialized.current !== serialized) {
      prevSerialized.current = serialized;
      setValue(initialValue);
    }
  }, [serialized, initialValue]);

  return [value, setValue];
}
