'use client';

import { useEffect, useId, useMemo, useRef, useState } from 'react';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import { useTranslations } from 'next-intl';
import { formatAdminDate, useAdminBcp47Locale } from '@/lib/i18n';
import { Calendar } from '../calendar';
import { Field, fieldDescriptionId } from '../field';
import { Icon } from '../icon';
import { parseIsoDate } from '../calendar/calendar-utils';
import styles from './date-picker.module.css';

const SPRING = { type: 'spring' as const, stiffness: 420, damping: 32 };

export type DatePickerProps = {
  label: string;
  value?: string;
  onValueChange?: (value: string) => void;
  onChange?: (event: { target: { value: string } }) => void;
  errorText?: string;
  helperText?: string;
  disabled?: boolean;
  required?: boolean;
  min?: string;
  max?: string;
  placeholder?: string;
  size?: 'sm' | 'md';
  hideLabel?: boolean;
  className?: string;
  id?: string;
  name?: string;
};

export function DatePicker({
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
  max,
  placeholder,
  size = 'md',
  hideLabel = false,
  className,
  name,
}: DatePickerProps) {
  const t = useTranslations('ui');
  const locale = useAdminBcp47Locale();
  const reducedMotion = useReducedMotion();
  const fallbackId = useId();
  const inputId = id ?? fallbackId;
  const panelId = useId();
  const containerRef = useRef<HTMLDivElement>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);
  const [open, setOpen] = useState(false);
  const descriptionId = fieldDescriptionId(inputId, errorText, helperText);

  const displayValue = useMemo(() => {
    if (!value) return '';
    const parsed = parseIsoDate(value);
    return parsed ? formatAdminDate(parsed, locale) : value;
  }, [locale, value]);

  function emitChange(nextValue: string) {
    onValueChange?.(nextValue);
    onChange?.({ target: { value: nextValue } });
  }

  function close() {
    setOpen(false);
    triggerRef.current?.focus();
  }

  function handleSelect(nextValue: string) {
    emitChange(nextValue);
    close();
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
              {displayValue || placeholder || t('calendar.selectDate')}
            </span>
            {!value ? <Icon name="chevron-down" size={14} className={styles.chevron} aria-hidden /> : null}
          </button>
          {value ? (
            <button
              type="button"
              className={styles.clearButton}
              aria-label={t('calendar.clearDate')}
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
                value={value}
                {...(min ? { min } : {})}
                {...(max ? { max } : {})}
                onSelect={handleSelect}
              />
            </motion.div>
          ) : null}
        </AnimatePresence>
      </div>
    </Field>
  );
}
