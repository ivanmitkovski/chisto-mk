'use client';

import { useCallback, useEffect, useState } from 'react';

export type OverlayPhase = 'hidden' | 'enter' | 'open' | 'exit';

export function useOverlayAnimation(open: boolean) {
  const [phase, setPhase] = useState<OverlayPhase>(open ? 'enter' : 'hidden');

  useEffect(() => {
    if (open) {
      setPhase('enter');
      let innerFrame = 0;
      const outerFrame = requestAnimationFrame(() => {
        innerFrame = requestAnimationFrame(() => setPhase('open'));
      });
      return () => {
        cancelAnimationFrame(outerFrame);
        cancelAnimationFrame(innerFrame);
      };
    }
    setPhase((current) => (current === 'hidden' ? 'hidden' : 'exit'));
    return undefined;
  }, [open]);

  const finishExit = useCallback(() => setPhase('hidden'), []);

  useEffect(() => {
    if (phase !== 'exit') return undefined;
    const fallbackMs = process.env.VITEST ? 0 : 320;
    const id = window.setTimeout(finishExit, fallbackMs);
    return () => window.clearTimeout(id);
  }, [phase, finishExit]);

  return {
    mounted: phase !== 'hidden',
    phase,
    finishExit,
  };
}
