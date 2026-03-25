'use client';

import { useEffect, useRef } from 'react';
import {
  getReportSoundPreference,
  getReducedMotionPreference,
} from '@/lib/admin-preferences';
import { subscribeNewReportSignal } from '@/lib/realtime-signals';

const MIN_SOUND_INTERVAL_MS = 4000;
const DEBUG_REALTIME_FLAG = 'chisto:debug-realtime';

function isRealtimeDebugEnabled(): boolean {
  if (typeof window === 'undefined') return false;
  return process.env.NODE_ENV !== 'production' && window.localStorage.getItem(DEBUG_REALTIME_FLAG) === '1';
}

function playChime(): void {
  const AudioCtx = window.AudioContext || (window as Window & { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
  if (!AudioCtx) return;
  const ctx = new AudioCtx();
  const now = ctx.currentTime;

  const master = ctx.createGain();
  master.gain.value = 0.0001;
  master.connect(ctx.destination);
  master.gain.exponentialRampToValueAtTime(0.18, now + 0.02);
  master.gain.exponentialRampToValueAtTime(0.0001, now + 0.62);

  const first = ctx.createOscillator();
  first.type = 'sine';
  first.frequency.value = 1046.5;
  first.connect(master);
  first.start(now);
  first.stop(now + 0.16);

  const second = ctx.createOscillator();
  second.type = 'triangle';
  second.frequency.value = 1318.5;
  second.connect(master);
  second.start(now + 0.14);
  second.stop(now + 0.35);

  window.setTimeout(() => {
    void ctx.close().catch(() => {});
  }, 1000);
}

export function NewReportSoundEffect() {
  const lastPlayedRef = useRef(0);
  const hasInteractionRef = useRef(false);

  useEffect(() => {
    const unlock = () => {
      hasInteractionRef.current = true;
      window.removeEventListener('pointerdown', unlock, true);
      window.removeEventListener('keydown', unlock, true);
    };
    window.addEventListener('pointerdown', unlock, true);
    window.addEventListener('keydown', unlock, true);
    return () => {
      window.removeEventListener('pointerdown', unlock, true);
      window.removeEventListener('keydown', unlock, true);
    };
  }, []);

  useEffect(() => {
    return subscribeNewReportSignal(() => {
      if (!hasInteractionRef.current) return;
      if (!getReportSoundPreference()) return;
      if (getReducedMotionPreference()) return;
      const now = Date.now();
      if (now - lastPlayedRef.current < MIN_SOUND_INTERVAL_MS) return;
      lastPlayedRef.current = now;
      if (isRealtimeDebugEnabled()) {
        console.debug('[realtime] sound-chime', { atMs: now });
      }
      playChime();
    });
  }, []);

  return null;
}
