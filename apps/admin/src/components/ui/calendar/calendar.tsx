'use client';

import { useEffect, useId, useMemo, useRef, useState } from 'react';
import { useTranslations } from 'next-intl';
import { useAdminBcp47Locale } from '@/lib/i18n';
import { Icon } from '../icon';
import {
  addMonths,
  buildMonthGrid,
  formatIsoDate,
  isDateDisabled,
  isSameDay,
  monthYearLabel,
  parseIsoDate,
  weekdayLabels,
} from './calendar-utils';
import styles from './calendar.module.css';

export type CalendarProps = {
  value?: string;
  onSelect: (isoDate: string) => void;
  min?: string;
  max?: string;
  weekStartsOn?: number;
  className?: string;
};

export function Calendar({
  value = '',
  onSelect,
  min,
  max,
  weekStartsOn = 1,
  className,
}: CalendarProps) {
  const t = useTranslations('ui');
  const locale = useAdminBcp47Locale();
  const labelId = useId();
  const selectedDate = useMemo(() => (value ? parseIsoDate(value) : null), [value]);
  const [viewMonth, setViewMonth] = useState(() => selectedDate ?? new Date());
  const [focusedIso, setFocusedIso] = useState(() => value || formatIsoDate(new Date()));
  const dayButtonRefs = useRef<Map<string, HTMLButtonElement>>(new Map());

  useEffect(() => {
    if (selectedDate) {
      setViewMonth(selectedDate);
      setFocusedIso(formatIsoDate(selectedDate));
    }
  }, [value, selectedDate]);

  const today = useMemo(() => new Date(), []);
  const todayIso = formatIsoDate(today);
  const weekdays = useMemo(() => weekdayLabels(locale, weekStartsOn), [locale, weekStartsOn]);
  const cells = useMemo(() => buildMonthGrid(viewMonth, weekStartsOn), [viewMonth, weekStartsOn]);

  function moveFocus(iso: string) {
    setFocusedIso(iso);
    dayButtonRefs.current.get(iso)?.focus();
  }

  function handleDayKeyDown(
    event: React.KeyboardEvent<HTMLButtonElement>,
    iso: string,
    date: Date,
    index: number,
  ) {
    const column = index % 7;
    const row = Math.floor(index / 7);

    if (event.key === 'ArrowLeft') {
      event.preventDefault();
      moveFocus(cells[Math.max(0, index - 1)]!.iso);
    } else if (event.key === 'ArrowRight') {
      event.preventDefault();
      moveFocus(cells[Math.min(cells.length - 1, index + 1)]!.iso);
    } else if (event.key === 'ArrowUp') {
      event.preventDefault();
      moveFocus(cells[Math.max(0, index - 7)]!.iso);
    } else if (event.key === 'ArrowDown') {
      event.preventDefault();
      moveFocus(cells[Math.min(cells.length - 1, index + 7)]!.iso);
    } else if (event.key === 'Home') {
      event.preventDefault();
      moveFocus(cells[row * 7]!.iso);
    } else if (event.key === 'End') {
      event.preventDefault();
      moveFocus(cells[row * 7 + 6]!.iso);
    } else if (event.key === 'PageUp') {
      event.preventDefault();
      setViewMonth((current) => addMonths(current, -1));
    } else if (event.key === 'PageDown') {
      event.preventDefault();
      setViewMonth((current) => addMonths(current, 1));
    } else if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      if (!isDateDisabled(date, min, max)) {
        onSelect(iso);
      }
    }
    void column;
  }

  const rootClassName = [styles.calendar, className ?? ''].join(' ').trim();

  return (
    <div className={rootClassName} role="application" aria-labelledby={labelId}>
      <div className={styles.header}>
        <button
          type="button"
          className={styles.navButton}
          onClick={() => setViewMonth((current) => addMonths(current, -1))}
          aria-label={t('calendar.previousMonth')}
        >
          <Icon name="chevron-left" size={16} aria-hidden />
        </button>
        <div id={labelId} className={styles.monthLabel} aria-live="polite">
          {monthYearLabel(viewMonth, locale)}
        </div>
        <button
          type="button"
          className={styles.navButton}
          onClick={() => setViewMonth((current) => addMonths(current, 1))}
          aria-label={t('calendar.nextMonth')}
        >
          <Icon name="chevron-right" size={16} aria-hidden />
        </button>
      </div>

      <div className={styles.weekdays} aria-hidden>
        {weekdays.map((label) => (
          <span key={label} className={styles.weekday}>
            {label}
          </span>
        ))}
      </div>

      <div className={styles.grid} role="grid" aria-label={t('calendar.days')}>
        {cells.map((cell, index) => {
          const disabled = isDateDisabled(cell.date, min, max);
          const selected = selectedDate ? isSameDay(cell.date, selectedDate) : false;
          const isToday = isSameDay(cell.date, today);
          const dayClassName = [
            styles.day,
            !cell.inMonth ? styles.dayOutside : '',
            isToday ? styles.dayToday : '',
            selected ? styles.daySelected : '',
            disabled ? styles.dayDisabled : '',
          ]
            .filter(Boolean)
            .join(' ');

          return (
            <button
              key={cell.iso}
              ref={(node) => {
                if (node) dayButtonRefs.current.set(cell.iso, node);
                else dayButtonRefs.current.delete(cell.iso);
              }}
              type="button"
              role="gridcell"
              className={dayClassName}
              tabIndex={focusedIso === cell.iso ? 0 : -1}
              disabled={disabled}
              aria-selected={selected}
              aria-current={isToday ? 'date' : undefined}
              aria-label={cell.date.toLocaleDateString(locale, {
                weekday: 'long',
                month: 'long',
                day: 'numeric',
                year: 'numeric',
              })}
              onClick={() => onSelect(cell.iso)}
              onFocus={() => setFocusedIso(cell.iso)}
              onKeyDown={(event) => handleDayKeyDown(event, cell.iso, cell.date, index)}
            >
              {cell.date.getDate()}
            </button>
          );
        })}
      </div>

      <div className={styles.footer}>
        <button
          type="button"
          className={styles.todayButton}
          onClick={() => {
            if (!isDateDisabled(today, min, max)) {
              onSelect(todayIso);
              setViewMonth(today);
            }
          }}
        >
          {t('calendar.today')}
        </button>
      </div>
    </div>
  );
}
