'use client';

import { useCallback, useEffect, useId, useMemo, useRef, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Field } from '../field';
import styles from './combobox.module.css';

export type ComboboxOption = { value: string; label: string };

type ComboboxProps = {
  label: string;
  value: string;
  options: ComboboxOption[];
  placeholder?: string;
  disabled?: boolean;
  onChange: (value: string) => void;
};

export function Combobox({
  label,
  value,
  options,
  placeholder,
  disabled = false,
  onChange,
}: ComboboxProps) {
  const t = useTranslations('common');
  const resolvedPlaceholder = placeholder ?? t('comboboxSearch');
  const inputId = useId();
  const listId = useId();
  const rootRef = useRef<HTMLDivElement | null>(null);
  const inputRef = useRef<HTMLInputElement | null>(null);
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState('');
  const [activeIndex, setActiveIndex] = useState(-1);

  const selectedLabel = options.find((option) => option.value === value)?.label ?? '';
  const displayValue = open ? query : selectedLabel;

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return q ? options.filter((option) => option.label.toLowerCase().includes(q)) : options;
  }, [options, query]);

  const close = useCallback(() => {
    setOpen(false);
    setQuery('');
    setActiveIndex(-1);
  }, []);

  useEffect(() => {
    if (!open) return undefined;
    const onPointerDown = (event: MouseEvent) => {
      if (!rootRef.current?.contains(event.target as Node)) {
        close();
      }
    };
    document.addEventListener('pointerdown', onPointerDown);
    return () => document.removeEventListener('pointerdown', onPointerDown);
  }, [close, open]);

  useEffect(() => {
    if (!open) return;
    setActiveIndex(filtered.length > 0 ? 0 : -1);
  }, [filtered.length, open, query]);

  const selectOption = (option: ComboboxOption) => {
    onChange(option.value);
    close();
    inputRef.current?.focus();
  };

  const activeOptionId = activeIndex >= 0 ? `${listId}-option-${activeIndex}` : undefined;

  const onKeyDown = (event: React.KeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'Escape') {
      event.preventDefault();
      close();
      return;
    }

    if (event.key === 'ArrowDown') {
      event.preventDefault();
      if (!open) {
        setOpen(true);
        setQuery('');
        return;
      }
      if (filtered.length === 0) return;
      setActiveIndex((current) => Math.min(current + 1, filtered.length - 1));
      return;
    }

    if (event.key === 'ArrowUp') {
      event.preventDefault();
      if (!open) {
        setOpen(true);
        setQuery('');
        return;
      }
      if (filtered.length === 0) return;
      setActiveIndex((current) => Math.max(current - 1, 0));
      return;
    }

    if (event.key === 'Home' && open && filtered.length > 0) {
      event.preventDefault();
      setActiveIndex(0);
      return;
    }

    if (event.key === 'End' && open && filtered.length > 0) {
      event.preventDefault();
      setActiveIndex(filtered.length - 1);
      return;
    }

    if (event.key === 'Enter' && open && activeIndex >= 0) {
      event.preventDefault();
      const option = filtered[activeIndex];
      if (option) selectOption(option);
    }
  };

  return (
    <Field label={label} htmlFor={inputId} className={styles.root}>
      <div ref={rootRef} className={styles.control}>
        <input
          ref={inputRef}
          id={inputId}
          role="combobox"
          aria-expanded={open}
          aria-controls={listId}
          aria-activedescendant={open ? activeOptionId : undefined}
          aria-autocomplete="list"
          aria-haspopup="listbox"
          disabled={disabled}
          value={displayValue}
          placeholder={resolvedPlaceholder}
          onChange={(event) => {
            setQuery(event.target.value);
            setOpen(true);
          }}
          onFocus={() => {
            setOpen(true);
            setQuery('');
          }}
          onKeyDown={onKeyDown}
        />
        {open ? (
          <div id={listId} className={styles.options} role="listbox" aria-labelledby={inputId}>
            {filtered.length === 0 ? (
              <div className={styles.emptyOption} role="presentation">
                {t('comboboxNoOptions')}
              </div>
            ) : (
              filtered.map((option, index) => (
                <button
                  key={option.value}
                  id={`${listId}-option-${index}`}
                  type="button"
                  role="option"
                  aria-selected={option.value === value}
                  className={index === activeIndex ? styles.optionActive : undefined}
                  onMouseEnter={() => setActiveIndex(index)}
                  onClick={() => selectOption(option)}
                >
                  {option.label}
                </button>
              ))
            )}
          </div>
        ) : null}
      </div>
    </Field>
  );
}
