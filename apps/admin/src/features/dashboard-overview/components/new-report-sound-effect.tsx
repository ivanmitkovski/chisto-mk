'use client';

import { useEffect, useRef } from 'react';
import { getReportSoundPreference } from '@/lib/admin-preferences';
import {
  isReportAudioUnlocked,
  playReportChime,
  teardownReportAudio,
  unlockReportAudioFromUserGesture,
} from '@/lib/admin-report-audio';
import { subscribeNewReportSignal } from '@/lib/realtime-signals';

const MIN_SOUND_INTERVAL_MS = 4000;
const DEBUG_REALTIME_FLAG = 'chisto:debug-realtime';

/** Dev: localStorage.setItem('chisto:debug-realtime','1') — see SSE + sound logs in console. */
function isRealtimeDebugEnabled(): boolean {
  if (typeof window === 'undefined') return false;
  return process.env.NODE_ENV !== 'production' && window.localStorage.getItem(DEBUG_REALTIME_FLAG) === '1';
}

export function NewReportSoundEffect() {
  const lastPlayedRef = useRef(0);
  const hasQueuedBurstRef = useRef(false);
  const trailingChimeTimeoutRef = useRef<number | null>(null);

  useEffect(() => {
    const onGesture = () => {
      void unlockReportAudioFromUserGesture().then((ok) => {
        if (ok) {
          window.removeEventListener('pointerdown', onGesture, true);
          window.removeEventListener('keydown', onGesture, true);
          if (isRealtimeDebugEnabled()) {
            console.debug('[realtime] sound-unlocked');
          }
        } else if (isRealtimeDebugEnabled()) {
          console.debug('[realtime] sound-unlock-retry', { message: 'will retry on next gesture' });
        }
      });
    };
    window.addEventListener('pointerdown', onGesture, true);
    window.addEventListener('keydown', onGesture, true);
    return () => {
      window.removeEventListener('pointerdown', onGesture, true);
      window.removeEventListener('keydown', onGesture, true);
      if (trailingChimeTimeoutRef.current != null) {
        window.clearTimeout(trailingChimeTimeoutRef.current);
        trailingChimeTimeoutRef.current = null;
      }
      teardownReportAudio();
    };
  }, []);

  useEffect(() => {
    const maybePlayTrailingChime = () => {
      trailingChimeTimeoutRef.current = null;
      if (!hasQueuedBurstRef.current) {
        return;
      }
      hasQueuedBurstRef.current = false;
      if (!isReportAudioUnlocked() || !getReportSoundPreference()) {
        if (isRealtimeDebugEnabled()) {
          console.debug('[realtime] sound-skip', { reason: 'trailing-chime-gated' });
        }
        return;
      }
      const now = Date.now();
      lastPlayedRef.current = now;
      if (isRealtimeDebugEnabled()) {
        console.debug('[realtime] sound-chime', { atMs: now, mode: 'trailing' });
      }
      playReportChime();
    };

    return subscribeNewReportSignal(() => {
      if (!isReportAudioUnlocked()) {
        if (isRealtimeDebugEnabled()) {
          console.debug('[realtime] sound-skip', { reason: 'no-user-interaction-yet' });
        }
        return;
      }
      if (!getReportSoundPreference()) {
        if (isRealtimeDebugEnabled()) {
          console.debug('[realtime] sound-skip', { reason: 'sound-preference-disabled' });
        }
        return;
      }
      const now = Date.now();
      const msSinceLast = now - lastPlayedRef.current;
      if (msSinceLast < MIN_SOUND_INTERVAL_MS) {
        hasQueuedBurstRef.current = true;
        const waitMs = MIN_SOUND_INTERVAL_MS - msSinceLast;
        if (trailingChimeTimeoutRef.current == null) {
          trailingChimeTimeoutRef.current = window.setTimeout(maybePlayTrailingChime, waitMs);
        }
        if (isRealtimeDebugEnabled()) {
          console.debug('[realtime] sound-coalesced', { reason: 'rate-limited', waitMs });
        }
        return;
      }
      hasQueuedBurstRef.current = false;
      if (trailingChimeTimeoutRef.current != null) {
        window.clearTimeout(trailingChimeTimeoutRef.current);
        trailingChimeTimeoutRef.current = null;
      }
      lastPlayedRef.current = now;
      if (isRealtimeDebugEnabled()) {
        console.debug('[realtime] sound-chime', { atMs: now, mode: 'immediate' });
      }
      playReportChime();
    });
  }, []);

  return null;
}
