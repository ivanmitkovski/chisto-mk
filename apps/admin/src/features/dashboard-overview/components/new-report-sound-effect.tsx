'use client';

import { useEffect, useRef } from 'react';
import {
  getReportSoundPreference,
} from '@/lib/admin-preferences';
import { subscribeNewReportSignal } from '@/lib/realtime-signals';

const MIN_SOUND_INTERVAL_MS = 4000;
const DEBUG_REALTIME_FLAG = 'chisto:debug-realtime';

function isRealtimeDebugEnabled(): boolean {
  if (typeof window === 'undefined') return false;
  return process.env.NODE_ENV !== 'production' && window.localStorage.getItem(DEBUG_REALTIME_FLAG) === '1';
}

function getAudioContextConstructor(): (typeof AudioContext) | null {
  const w = window as Window & { webkitAudioContext?: typeof AudioContext };
  return window.AudioContext ?? w.webkitAudioContext ?? null;
}

function playChimeOnContext(ctx: AudioContext): void {
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
}

export function NewReportSoundEffect() {
  const lastPlayedRef = useRef(0);
  const hasInteractionRef = useRef(false);
  const audioContextRef = useRef<AudioContext | null>(null);
  const triedGestureUnlockRef = useRef(false);

  useEffect(() => {
    const unlock = () => {
      if (triedGestureUnlockRef.current) {
        return;
      }
      triedGestureUnlockRef.current = true;
      const Ctor = getAudioContextConstructor();
      if (!Ctor) {
        if (isRealtimeDebugEnabled()) {
          console.debug('[realtime] sound-skip', { reason: 'audio-context-unsupported' });
        }
        return;
      }
      if (!audioContextRef.current) {
        audioContextRef.current = new Ctor();
      }
      const ctx = audioContextRef.current;
      if (!ctx) {
        return;
      }
      void ctx.resume().then(() => {
        hasInteractionRef.current = true;
        if (isRealtimeDebugEnabled()) {
          console.debug('[realtime] sound-unlocked', { state: ctx.state });
        }
      }).catch(() => {
        if (isRealtimeDebugEnabled()) {
          console.debug('[realtime] sound-skip', { reason: 'resume-failed' });
        }
      });
      window.removeEventListener('pointerdown', unlock, true);
      window.removeEventListener('keydown', unlock, true);
    };
    window.addEventListener('pointerdown', unlock, true);
    window.addEventListener('keydown', unlock, true);
    return () => {
      window.removeEventListener('pointerdown', unlock, true);
      window.removeEventListener('keydown', unlock, true);
      const ctx = audioContextRef.current;
      audioContextRef.current = null;
      if (ctx) {
        void ctx.close().catch(() => {});
      }
    };
  }, []);

  useEffect(() => {
    return subscribeNewReportSignal(() => {
      if (!hasInteractionRef.current) {
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
      if (now - lastPlayedRef.current < MIN_SOUND_INTERVAL_MS) {
        if (isRealtimeDebugEnabled()) {
          console.debug('[realtime] sound-skip', { reason: 'rate-limited' });
        }
        return;
      }
      lastPlayedRef.current = now;
      if (isRealtimeDebugEnabled()) {
        console.debug('[realtime] sound-chime', { atMs: now });
      }

      const Ctor = getAudioContextConstructor();
      if (!Ctor) {
        if (isRealtimeDebugEnabled()) {
          console.debug('[realtime] sound-skip', { reason: 'audio-context-unsupported' });
        }
        return;
      }
      const ctx = audioContextRef.current;
      if (!ctx) {
        if (isRealtimeDebugEnabled()) {
          console.debug('[realtime] sound-skip', { reason: 'not-unlocked-yet' });
        }
        return;
      }

      const play = () => {
        try {
          playChimeOnContext(ctx);
        } catch {
          // ignore
        }
      };

      if (ctx.state === 'suspended') {
        void ctx.resume().then(play).catch(() => {
          if (isRealtimeDebugEnabled()) {
            console.debug('[realtime] sound-skip', { reason: 'resume-before-play-failed' });
          }
        });
      } else {
        play();
      }
    });
  }, []);

  return null;
}
