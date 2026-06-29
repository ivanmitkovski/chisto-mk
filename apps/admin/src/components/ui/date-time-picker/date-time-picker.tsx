'use client';

import { useEffect, useId, useMemo, useRef, useState } from 'react';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import { useTranslations } from 'next-intl';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import {
  fromDatetimeLocalValue,
  joinDatetimeLocal,
  minTimeForDate,
  snapTimeToStep,
  splitDatetimeLocal,
} from '@/lib/datetime/datetime-local';
import { Calendar } from '../calendar';
import { formatIsoDate } from '../calendar/calendar-utils';
import { Field, fieldDescriptionId } from '../field';
import { Icon } from '../icon';
import { TimePicker } from '../time-picker';
import styles from './date-time-picker.module.css';

const SPRING = { type: 'spring' as const, stiffness: 420, damping: 32 };
const DEFAULT_TIME = '10:00';

export type DateTimePickerProps = {
  label: string;
  value?: string | undefined;
  onValueChange?: ((value: string) => void) | undefined;
  onChange?: ((event: { target: { value: string } }) => void) | undefined;
  errorText?: string | undefined;
  helperText?: string | undefined;
  disabled?: boolean | undefined;
  required?: boolean | undefined;
  min?: string | undefined;
  placeholder?: string | undefined;
  size?: 'sm' | 'md' | undefined;
  hideLabel?: boolean | undefined;
  className?: string | undefined;
  id?: string | undefined;
  name?: string | undefined;
};

export function DateTimePicker({
  id,
  label,
  value = '',
  onValueChange,
  onChange,
  errorText,
  helperText,
  disabled = false,
  required,
  min,
  placeholder,
  size = 'md',
  hideLabel = false,
  className,
  name,
}: DateTimePickerProps) {
  const t = useTranslations('ui');
  const locale = useAdminBcp47Locale();
  const reducedMotion = useReducedMotion();
  const fallbackId = useId();
  const inputId = id ?? fallbackId;
  const panelId = useId();
  const containerRef = useRef<HTMLDivElement>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);
  const panelRef = useRef<HTMLDivElement>(null);
  const [open, setOpen] = useState(false);
  const descriptionId = fieldDescriptionId(inputId, errorText, helperText);

  const { date, time } = useMemo(() => {
    const parts = splitDatetimeLocal(value, DEFAULT_TIME);
    return { date: parts.date, time: snapTimeToStep(parts.time) };
  }, [value]);
  const minDate = min ?? formatIsoDate(new Date());
  const minTime = date ? minTimeForDate(date) : undefined;

  const displayValue = useMemo(() => {
    if (!value) return '';
    const iso = fromDatetimeLocalValue(value);
    return iso ? formatAdminDateTime(iso, locale) : value;
  }, [locale, value]);

  function emitChange(nextValue: string) {
    onValueChange?.(nextValue);
    onChange?.({ target: { value: nextValue } });
  }

  function close() {
    setOpen(false);
    triggerRef.current?.focus();
  }

  function handleDateSelect(nextDate: string) {
    const nextTime = value ? time : snapTimeToStep(DEFAULT_TIME);
    emitChange(joinDatetimeLocal(nextDate, nextTime));
  }

  function handleTimeChange(nextTime: string) {
    const snapped = snapTimeToStep(nextTime);
    if (!date) {
      emitChange(joinDatetimeLocal(minDate, snapped));
      return;
    }
    emitChange(joinDatetimeLocal(date, snapped));
  }

  function handleClear(event: React.MouseEvent<HTMLButtonElement>) {
    event.stopPropagation();
    emitChange('');
    close();
  }

  useEffect(() => {
    if (!open) return undefined;

    const onPointerDown = (event: PointerEvent) => {
      if (!containerRef.current?.contains(event.target as Node)) {
        close();
      }
    };

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        close();
      }
    };

    window.addEventListener('pointerdown', onPointerDown);
    window.addEventListener('keydown', onKeyDown);
    return () => {
      window.removeEventListener('pointerdown', onPointerDown);
      window.removeEventListener('keydown', onKeyDown);
    };
  }, [open]);

  useEffect(() => {
    if (!open) return;
    const panel = panelRef.current;
    if (!panel) return;
    panel.scrollTop = 0;
  }, [open]);

  const triggerClassName = [styles.trigger, size === 'sm' ? styles.triggerSm : ''].filter(Boolean).join(' ');
  const wrapClassName = [
    styles.triggerWrap,
    errorText ? styles.triggerError : '',
    disabled ? styles.triggerDisabled : '',
    open ? styles.triggerOpen : '',
    className ?? '',
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <Field
      label={hideLabel ? undefined : label}
      htmlFor={inputId}
      helperText={helperText}
      errorText={errorText}
      required={required}
      className={styles.field}
    >
      <div className={styles.root} ref={containerRef}>
        <div className={wrapClassName}>
          <button
            ref={triggerRef}
            id={inputId}
            type="button"
            className={triggerClassName}
            disabled={disabled}
            aria-haspopup="dialog"
            aria-expanded={open}
            aria-controls={panelId}
            aria-invalid={Boolean(errorText)}
            aria-describedby={descriptionId}
            aria-label={hideLabel ? label : undefined}
            onClick={() => setOpen((current) => !current)}
          >
            <Icon name="calendar" size={size === 'sm' ? 14 : 16} className={styles.leadingIcon} aria-hidden />
            <span className={[styles.value, !displayValue ? styles.placeholder : ''].filter(Boolean).join(' ')}>
              {displayValue || placeholder || t('calendar.selectDateTime')}
            </span>
            {!value ? <Icon name="chevron-down" size={14} className={styles.chevron} aria-hidden /> : null}
          </button>
          {value ? (
            <button
              type="button"
              className={styles.clearButton}
              aria-label={t('calendar.clearDateTime')}
              disabled={disabled}
              onClick={handleClear}
            >
              <Icon name="x" size={14} aria-hidden />
            </button>
          ) : null}
        </div>

        {name ? <input type="hidden" name={name} value={value} /> : null}

        <AnimatePresence>
          {open ? (
            <motion.div
              ref={panelRef}
              id={panelId}
              role="dialog"
              aria-label={label}
              className={styles.panel}
              initial={reducedMotion ? false : { opacity: 0, y: -6, scale: 0.98 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={reducedMotion ? { opacity: 0 } : { opacity: 0, y: -6, scale: 0.98 }}
              transition={reducedMotion ? { duration: 0 } : SPRING}
            >
              <Calendar
                value={date}
                min={minDate}
                onSelect={handleDateSelect}
              />
              <div className={styles.timeSection}>
                <TimePicker
                  id={`${inputId}-time`}
                  value={time}
                  disabled={disabled}
                  onChange={handleTimeChange}
                  aria-label={t('calendar.time')}
                  {...(minTime !== undefined ? { min: minTime } : {})}
                />
              </div>
            </motion.div>
          ) : null}
        </AnimatePresence>
      </div>
    </Field>
  );
}
