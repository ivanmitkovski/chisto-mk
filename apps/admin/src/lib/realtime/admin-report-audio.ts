/**
 * Shared Web Audio unlock + chime for "new report" alerts.
 * Unlock must run from a user gesture; callers may retry until `unlockReportAudioFromUserGesture` resolves true.
 * Optional file: place `new-report.mp3` at `public/sounds/new-report.mp3` for HTML5 fallback when oscillators fail.
 */

const FALLBACK_MP3_SRC = '/sounds/new-report.mp3';
const DEBUG_REALTIME_FLAG = 'chisto:debug-realtime';

let sharedCtx: AudioContext | null = null;
let unlocked = false;

function isRealtimeDebugEnabled(): boolean {
  if (typeof window === 'undefined') return false;
  return process.env.NODE_ENV !== 'production' && window.localStorage.getItem(DEBUG_REALTIME_FLAG) === '1';
}

function getAudioContextConstructor(): (typeof AudioContext) | null {
  if (typeof window === 'undefined') return null;
  const w = window as Window & { webkitAudioContext?: typeof AudioContext };
  return window.AudioContext ?? w.webkitAudioContext ?? null;
}

function playOscillatorChime(ctx: AudioContext): void {
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

function playHtmlAudioFallback(): void {
  try {
    const a = new Audio(FALLBACK_MP3_SRC);
    a.volume = 0.32;
    void a.play().then(() => {
      if (isRealtimeDebugEnabled()) {
        console.info('[realtime] audio-fallback-played', { src: FALLBACK_MP3_SRC });
      }
    }).catch(() => {
      if (isRealtimeDebugEnabled()) {
        console.info('[realtime] audio-fallback-failed', { src: FALLBACK_MP3_SRC });
      }
    });
  } catch {
    // Missing asset or autoplay blocked
    if (isRealtimeDebugEnabled()) {
      console.info('[realtime] audio-fallback-threw', { src: FALLBACK_MP3_SRC });
    }
  }
}

async function primeHtmlAudioFromUserGesture(): Promise<boolean> {
  try {
    const a = new Audio(FALLBACK_MP3_SRC);
    a.muted = true;
    a.volume = 0;
    await a.play();
    a.pause();
    a.currentTime = 0;
    if (isRealtimeDebugEnabled()) {
      console.info('[realtime] audio-fallback-primed', { src: FALLBACK_MP3_SRC });
    }
    return true;
  } catch {
    if (isRealtimeDebugEnabled()) {
      console.info('[realtime] audio-fallback-prime-failed', { src: FALLBACK_MP3_SRC });
    }
    return false;
  }
}

export function isReportAudioUnlocked(): boolean {
  return unlocked;
}

/** Call from pointer/tap/key handlers until it returns true (browser autoplay policy). */
export async function unlockReportAudioFromUserGesture(): Promise<boolean> {
  if (typeof window === 'undefined') return false;
  const htmlPrimed = await primeHtmlAudioFromUserGesture();
  const Ctor = getAudioContextConstructor();
  if (!Ctor) {
    unlocked = htmlPrimed;
    if (isRealtimeDebugEnabled()) {
      console.info('[realtime] audio-unlock-no-context-needed');
    }
    return htmlPrimed;
  }
  if (!sharedCtx) {
    sharedCtx = new Ctor();
  }
  try {
    await sharedCtx.resume();
  } catch {
    if (isRealtimeDebugEnabled()) {
      console.info('[realtime] audio-unlock-resume-failed');
    }
    unlocked = htmlPrimed;
    return htmlPrimed;
  }
  if (sharedCtx.state === 'running') {
    unlocked = true;
    if (isRealtimeDebugEnabled()) {
      console.info('[realtime] audio-unlocked', { state: sharedCtx.state });
    }
    return true;
  }
  if (isRealtimeDebugEnabled()) {
    console.info('[realtime] audio-unlock-not-running', { state: sharedCtx.state });
  }
  unlocked = htmlPrimed;
  return htmlPrimed;
}

/** Web Audio chime; falls back to HTMLAudio if oscillators throw. */
export function playReportChime(): void {
  if (sharedCtx && sharedCtx.state === 'running') {
    try {
      playOscillatorChime(sharedCtx);
      return;
    } catch {
      playHtmlAudioFallback();
      return;
    }
  }
  playHtmlAudioFallback();
}

/** Softer preview for settings test (same timbre, lower peak). */
export function playReportChimePreview(): void {
  if (sharedCtx && sharedCtx.state === 'running') {
    try {
      const now = sharedCtx.currentTime;
      const master = sharedCtx.createGain();
      master.gain.value = 0.0001;
      master.connect(sharedCtx.destination);
      master.gain.exponentialRampToValueAtTime(0.09, now + 0.02);
      master.gain.exponentialRampToValueAtTime(0.0001, now + 0.5);
      const o = sharedCtx.createOscillator();
      o.type = 'sine';
      o.frequency.value = 880;
      o.connect(master);
      o.start(now);
      o.stop(now + 0.12);
      return;
    } catch {
      playHtmlAudioFallback();
      return;
    }
  }
  playHtmlAudioFallback();
}

export function teardownReportAudio(): void {
  unlocked = false;
  if (sharedCtx) {
    void sharedCtx.close().catch(() => {});
    sharedCtx = null;
  }
}
