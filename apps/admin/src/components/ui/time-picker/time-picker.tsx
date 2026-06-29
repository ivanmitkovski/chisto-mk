'use client';

import { useEffect, useId, useRef } from 'react';
import { useTranslations } from 'next-intl';
import {
  buildHourOptions,
  buildMinuteOptions,
  formatTimeValue,
  isHourDisabled,
  isMinuteDisabled,
  parseTimeValue,
  snapTimeToStep,
} from '@/lib/datetime/datetime-local';
import styles from './time-picker.module.css';

/** Scroll inside the wheel only — never scroll ancestor popovers or the page. */
export function scrollWheelToOption(
  list: HTMLElement | null,
  optionId: string,
  behavior: ScrollBehavior = 'auto',
): void {
  if (!list) return;
  const option = list.querySelector<HTMLElement>(`#${CSS.escape(optionId)}`);
  if (!option) return;

  const listHeight = list.clientHeight;
  const optionHeight = option.offsetHeight;
  const optionTop = option.offsetTop;
  const targetTop = optionTop - (listHeight - optionHeight) / 2;
  const maxTop = Math.max(0, list.scrollHeight - listHeight);

  list.scrollTo({
    top: Math.min(maxTop, Math.max(0, targetTop)),
    behavior,
  });
}

function prefersReducedMotion(): boolean {
  if (typeof window === 'undefined' || typeof window.matchMedia !== 'function') {
    return false;
  }
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

const DEFAULT_MINUTE_STEP = 5;

export type TimePickerProps = {
  value: string;
  onChange: (value: string) => void;
  min?: string;
  disabled?: boolean;
  minuteStep?: number;
  id?: string;
  'aria-label'?: string;
  className?: string;
};

export function TimePicker({
  value,
  onChange,
  min,
  disabled = false,
  minuteStep = DEFAULT_MINUTE_STEP,
  id,
  'aria-label': ariaLabel,
  className,
}: TimePickerProps) {
  const t = useTranslations('ui');
  const fallbackId = useId();
  const rootId = id ?? fallbackId;
  const normalizedValue = snapTimeToStep(value || '10:00', minuteStep);
  const { hour, minute } = parseTimeValue(normalizedValue);
  const hours = buildHourOptions();
  const minutes = buildMinuteOptions(minuteStep);
  const hourListRef = useRef<HTMLDivElement>(null);
  const minuteListRef = useRef<HTMLDivElement>(null);
  const hasAlignedWheelsRef = useRef(false);

  useEffect(() => {
    const behavior: ScrollBehavior =
      hasAlignedWheelsRef.current && !prefersReducedMotion() ? 'smooth' : 'auto';
    const frame = requestAnimationFrame(() => {
      scrollWheelToOption(hourListRef.current, `${rootId}-hour-${hour}`, behavior);
      scrollWheelToOption(minuteListRef.current, `${rootId}-minute-${minute}`, behavior);
      hasAlignedWheelsRef.current = true;
    });
    return () => cancelAnimationFrame(frame);
  }, [hour, minute, rootId]);

  function selectHour(nextHour: number) {
    if (disabled || isHourDisabled(nextHour, min)) return;
    let nextMinute = minute;
    if (min && isMinuteDisabled(nextMinute, nextHour, min)) {
      const { minute: minMinute } = parseTimeValue(min);
      nextMinute = minMinute;
    }
    onChange(formatTimeValue(nextHour, nextMinute));
  }

  function selectMinute(nextMinute: number) {
    if (disabled || isMinuteDisabled(nextMinute, hour, min)) return;
    onChange(formatTimeValue(hour, nextMinute));
  }

  const rootClassName = [styles.root, className ?? ''].filter(Boolean).join(' ');

  return (
    <div
      className={rootClassName}
      role="group"
      aria-label={ariaLabel ?? t('calendar.time')}
      aria-disabled={disabled || undefined}
    >
      <div className={styles.columns}>
        <div className={styles.column}>
          <span className={styles.columnLabel} id={`${rootId}-hour-label`}>
            {t('calendar.hour')}
          </span>
          <div className={styles.scrollViewport} aria-labelledby={`${rootId}-hour-label`}>
            <div className={styles.scrollFadeTop} aria-hidden />
            <div className={styles.scrollFadeBottom} aria-hidden />
            <div className={styles.selectionBand} aria-hidden />
            <div ref={hourListRef} className={styles.scrollList} role="listbox" aria-label={t('calendar.hour')}>
              {hours.map((optionHour) => {
                const selected = optionHour === hour;
                const optionDisabled = disabled || isHourDisabled(optionHour, min);
                return (
                  <button
                    key={optionHour}
                    id={`${rootId}-hour-${optionHour}`}
                    type="button"
                    role="option"
                    aria-selected={selected}
                    disabled={optionDisabled}
                    className={[
                      styles.option,
                      selected ? styles.optionSelected : '',
                      optionDisabled ? styles.optionDisabled : '',
                    ]
                      .filter(Boolean)
                      .join(' ')}
                    onClick={() => selectHour(optionHour)}
                  >
                    {String(optionHour).padStart(2, '0')}
                  </button>
                );
              })}
            </div>
          </div>
        </div>

        <span className={styles.separator} aria-hidden>
          :
        </span>

        <div className={styles.column}>
          <span className={styles.columnLabel} id={`${rootId}-minute-label`}>
            {t('calendar.minute')}
          </span>
          <div className={styles.scrollViewport} aria-labelledby={`${rootId}-minute-label`}>
            <div className={styles.scrollFadeTop} aria-hidden />
            <div className={styles.scrollFadeBottom} aria-hidden />
            <div className={styles.selectionBand} aria-hidden />
            <div
              ref={minuteListRef}
              className={styles.scrollList}
              role="listbox"
              aria-label={t('calendar.minute')}
            >
              {minutes.map((optionMinute) => {
                const selected = optionMinute === minute;
                const optionDisabled = disabled || isMinuteDisabled(optionMinute, hour, min);
                return (
                  <button
                    key={optionMinute}
                    id={`${rootId}-minute-${optionMinute}`}
                    type="button"
                    role="option"
                    aria-selected={selected}
                    disabled={optionDisabled}
                    className={[
                      styles.option,
                      selected ? styles.optionSelected : '',
                      optionDisabled ? styles.optionDisabled : '',
                    ]
                      .filter(Boolean)
                      .join(' ')}
                    onClick={() => selectMinute(optionMinute)}
                  >
                    {String(optionMinute).padStart(2, '0')}
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
