export const ADMIN_REDUCED_MOTION_KEY = 'chisto.admin.ui.reducedMotion';
export const ADMIN_REPORT_SOUND_KEY = 'chisto.admin.notifications.reportSound';
export const ADMIN_REDUCED_MOTION_CLASS = 'chisto-admin-reduced-motion';

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

export function getReducedMotionPreference(): boolean {
  return readBooleanPref(ADMIN_REDUCED_MOTION_KEY);
}

export function setReducedMotionPreference(value: boolean): void {
  writeBooleanPref(ADMIN_REDUCED_MOTION_KEY, value);
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
