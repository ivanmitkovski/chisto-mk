'use client';

import { useCallback, useEffect, useState } from 'react';

export type OverlayPhase = 'hidden' | 'enter' | 'open' | 'exit';

export function useOverlayAnimation(open: boolean) {
  const [phase, setPhase] = useState<OverlayPhase>(open ? 'enter' : 'hidden');

  useEffect(() => {
    if (open) {
      setPhase('enter');
      const frame = requestAnimationFrame(() => {
        requestAnimationFrame(() => setPhase('open'));
      });
      return () => cancelAnimationFrame(frame);
    }
    setPhase((current) => (current === 'hidden' ? 'hidden' : 'exit'));
    return undefined;
  }, [open]);

  const finishExit = useCallback(() => setPhase('hidden'), []);

  useEffect(() => {
    if (phase !== 'exit') return undefined;
    const fallbackMs = 320;
    const id = window.setTimeout(finishExit, fallbackMs);
    return () => window.clearTimeout(id);
  }, [phase, finishExit]);

  return {
    mounted: phase !== 'hidden',
    phase,
    finishExit,
  };
}
