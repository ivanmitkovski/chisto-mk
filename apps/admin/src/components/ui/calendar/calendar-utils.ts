const ISO_DATE_RE = /^(\d{4})-(\d{2})-(\d{2})$/;

export function parseIsoDate(value: string): Date | null {
  const match = ISO_DATE_RE.exec(value);
  if (!match) return null;
  const year = Number(match[1]);
  const month = Number(match[2]) - 1;
  const day = Number(match[3]);
  const date = new Date(year, month, day);
  if (date.getFullYear() !== year || date.getMonth() !== month || date.getDate() !== day) {
    return null;
  }
  return date;
}

export function formatIsoDate(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

export function isSameDay(a: Date, b: Date): boolean {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

export function startOfMonth(date: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), 1);
}

export function addMonths(date: Date, delta: number): Date {
  return new Date(date.getFullYear(), date.getMonth() + delta, 1);
}

export function compareIsoDates(a: string, b: string): number {
  return a.localeCompare(b);
}

export function isDateDisabled(
  date: Date,
  min?: string,
  max?: string,
): boolean {
  const iso = formatIsoDate(date);
  if (min && compareIsoDates(iso, min) < 0) return true;
  if (max && compareIsoDates(iso, max) > 0) return true;
  return false;
}

export type CalendarDayCell = {
  date: Date;
  iso: string;
  inMonth: boolean;
};

/** Monday-first grid covering the month view (typically 42 cells). */
export function buildMonthGrid(viewMonth: Date, weekStartsOn = 1): CalendarDayCell[] {
  const firstOfMonth = startOfMonth(viewMonth);
  const startOffset = (firstOfMonth.getDay() - weekStartsOn + 7) % 7;
  const gridStart = new Date(firstOfMonth);
  gridStart.setDate(firstOfMonth.getDate() - startOffset);

  const cells: CalendarDayCell[] = [];
  for (let index = 0; index < 42; index += 1) {
    const date = new Date(gridStart);
    date.setDate(gridStart.getDate() + index);
    cells.push({
      date,
      iso: formatIsoDate(date),
      inMonth: date.getMonth() === viewMonth.getMonth(),
    });
  }
  return cells;
}

export function weekdayLabels(locale: string, weekStartsOn = 1): string[] {
  const formatter = new Intl.DateTimeFormat(locale, { weekday: 'short' });
  const monday = new Date(2024, 0, 1);
  const start = new Date(monday);
  if (weekStartsOn === 0) {
    start.setDate(monday.getDate() - 1);
  }
  const labels: string[] = [];
  for (let index = 0; index < 7; index += 1) {
    const day = new Date(start);
    day.setDate(start.getDate() + index);
    labels.push(formatter.format(day));
  }
  return labels;
}

export function monthYearLabel(date: Date, locale: string): string {
  return date.toLocaleDateString(locale, { month: 'long', year: 'numeric' });
}
