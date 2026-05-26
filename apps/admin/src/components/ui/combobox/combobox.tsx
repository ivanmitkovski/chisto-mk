'use client';

import { useMemo, useState } from 'react';
import styles from './combobox.module.css';

export type ComboboxOption = { value: string; label: string };

export function Combobox({
  label,
  value,
  options,
  placeholder = 'Search...',
  onChange,
}: {
  label: string;
  value: string;
  options: ComboboxOption[];
  placeholder?: string;
  onChange: (value: string) => void;
}) {
  const [query, setQuery] = useState('');
  const selectedLabel = options.find((option) => option.value === value)?.label ?? '';
  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return q ? options.filter((option) => option.label.toLowerCase().includes(q)) : options;
  }, [options, query]);

  return (
    <label className={styles.root}>
      <span>{label}</span>
      <input
        role="combobox"
        aria-expanded="true"
        aria-controls={`${label}-options`}
        value={query || selectedLabel}
        placeholder={placeholder}
        onChange={(event) => setQuery(event.target.value)}
        onFocus={() => setQuery('')}
      />
      <div id={`${label}-options`} className={styles.options} role="listbox">
        {filtered.map((option) => (
          <button
            key={option.value}
            type="button"
            role="option"
            aria-selected={option.value === value}
            onClick={() => {
              onChange(option.value);
              setQuery('');
            }}
          >
            {option.label}
          </button>
        ))}
      </div>
    </label>
  );
}
