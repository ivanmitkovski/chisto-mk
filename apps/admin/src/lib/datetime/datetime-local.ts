const DATETIME_LOCAL_RE = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})$/;

/** Browser-local `datetime-local` value (`YYYY-MM-DDTHH:mm`) from an ISO string. */
export function toDatetimeLocalValue(iso?: string | null): string {
  if (!iso) return '';
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return '';
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

/** ISO string from a `datetime-local` value, or `null` when empty/invalid. */
export function fromDatetimeLocalValue(value: string): string | null {
  const trimmed = value.trim();
  if (!trimmed) return null;
  const date = new Date(trimmed);
  if (Number.isNaN(date.getTime())) return null;
  return date.toISOString();
}

export function splitDatetimeLocal(
  value: string,
  defaultTime = '10:00',
): { date: string; time: string } {
  if (!value) return { date: '', time: defaultTime };
  const match = DATETIME_LOCAL_RE.exec(value);
  if (!match) {
    const parsed = new Date(value);
    if (Number.isNaN(parsed.getTime())) return { date: '', time: defaultTime };
    return {
      date: toDatetimeLocalValue(parsed.toISOString()).split('T')[0] ?? '',
      time: `${String(parsed.getHours()).padStart(2, '0')}:${String(parsed.getMinutes()).padStart(2, '0')}`,
    };
  }
  return { date: `${match[1]}-${match[2]}-${match[3]}`, time: `${match[4]}:${match[5]}` };
}

export function joinDatetimeLocal(date: string, time: string): string {
  if (!date) return '';
  const normalizedTime = time?.slice(0, 5) || '10:00';
  return `${date}T${normalizedTime}`;
}

const TIME_RE = /^(\d{2}):(\d{2})$/;

export type TimeParts = { hour: number; minute: number };

export function parseTimeValue(time: string): TimeParts {
  const match = TIME_RE.exec(time.slice(0, 5));
  if (!match) return { hour: 10, minute: 0 };
  return { hour: Number(match[1]), minute: Number(match[2]) };
}

export function formatTimeValue(hour: number, minute: number): string {
  const pad = (n: number) => String(n).padStart(2, '0');
  const h = Math.max(0, Math.min(23, hour));
  const m = Math.max(0, Math.min(59, minute));
  return `${pad(h)}:${pad(m)}`;
}

export function snapTimeToStep(time: string, step = 5): string {
  const { hour, minute } = parseTimeValue(time);
  let snapped = Math.round(minute / step) * step;
  let nextHour = hour;
  if (snapped >= 60) {
    snapped = 0;
    nextHour += 1;
  }
  if (nextHour > 23) nextHour = 23;
  return formatTimeValue(nextHour, snapped);
}

export function compareTime(a: string, b: string): number {
  const left = parseTimeValue(a);
  const right = parseTimeValue(b);
  if (left.hour !== right.hour) return left.hour - right.hour;
  return left.minute - right.minute;
}

export function buildHourOptions(): number[] {
  return Array.from({ length: 24 }, (_, hour) => hour);
}

export function buildMinuteOptions(step = 5): number[] {
  const options: number[] = [];
  for (let minute = 0; minute < 60; minute += step) {
    options.push(minute);
  }
  return options;
}

export function isHourDisabled(hour: number, min?: string): boolean {
  if (!min) return false;
  const { hour: minHour } = parseTimeValue(min);
  return hour < minHour;
}

export function isMinuteDisabled(minute: number, hour: number, min?: string): boolean {
  if (!min) return false;
  const { hour: minHour, minute: minMinute } = parseTimeValue(min);
  if (hour > minHour) return false;
  if (hour < minHour) return true;
  return minute < minMinute;
}

export function minTimeForDate(dateIso: string): string | undefined {
  const today = new Date();
  const pad = (n: number) => String(n).padStart(2, '0');
  const todayIso = `${today.getFullYear()}-${pad(today.getMonth() + 1)}-${pad(today.getDate())}`;
  if (dateIso !== todayIso) return undefined;
  return `${pad(today.getHours())}:${pad(today.getMinutes())}`;
}
