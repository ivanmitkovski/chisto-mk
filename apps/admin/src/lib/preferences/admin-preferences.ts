export const ADMIN_REDUCED_MOTION_KEY = 'chisto.admin.ui.reducedMotion';
export const ADMIN_REDUCED_MOTION_COOKIE = ADMIN_REDUCED_MOTION_KEY;
export const ADMIN_REPORT_SOUND_KEY = 'chisto.admin.notifications.reportSound';
export const ADMIN_REDUCED_MOTION_CLASS = 'chisto-admin-reduced-motion';

const REDUCED_MOTION_COOKIE_MAX_AGE = 60 * 60 * 24 * 365;

function readBooleanPref(key: string): boolean {
  if (typeof window === 'undefined') return false;
  try {
    return window.localStorage.getItem(key) === '1';
  } catch {
    return false;
  }
}

function writeBooleanPref(key: string, value: boolean): void {
  if (typeof window === 'undefined') return;
  try {
    if (value) {
      window.localStorage.setItem(key, '1');
    } else {
      window.localStorage.removeItem(key);
    }
  } catch {
    // ignore storage write failures
  }
}

export function setReducedMotionCookie(value: boolean): void {
  if (typeof document === 'undefined') return;
  if (value) {
    document.cookie = `${ADMIN_REDUCED_MOTION_COOKIE}=1; path=/; max-age=${REDUCED_MOTION_COOKIE_MAX_AGE}; SameSite=Lax`;
  } else {
    document.cookie = `${ADMIN_REDUCED_MOTION_COOKIE}=; path=/; max-age=0; SameSite=Lax`;
  }
}

export function getReducedMotionPreference(): boolean {
  return readBooleanPref(ADMIN_REDUCED_MOTION_KEY);
}

export function setReducedMotionPreference(value: boolean): void {
  writeBooleanPref(ADMIN_REDUCED_MOTION_KEY, value);
  setReducedMotionCookie(value);
  if (typeof document !== 'undefined') {
    document.documentElement.classList.toggle(ADMIN_REDUCED_MOTION_CLASS, value);
  }
}

export function getReportSoundPreference(): boolean {
  return readBooleanPref(ADMIN_REPORT_SOUND_KEY);
}

export function setReportSoundPreference(value: boolean): void {
  writeBooleanPref(ADMIN_REPORT_SOUND_KEY, value);
}
