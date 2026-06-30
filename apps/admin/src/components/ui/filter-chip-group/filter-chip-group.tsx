'use client';

import { Button } from '../button';
import styles from './filter-chip-group.module.css';

export type FilterChipOption = {
  value: string;
  label: string;
};

export type FilterChipGroupProps = {
  label: string;
  value: string;
  options: readonly FilterChipOption[];
  onChange: (value: string) => void;
  nowrap?: boolean;
  className?: string;
};

export function FilterChipGroup({
  label,
  value,
  options,
  onChange,
  nowrap = false,
  className,
}: FilterChipGroupProps) {
  const rootClass = [styles.root, className].filter(Boolean).join(' ');
  const chipsClass = [styles.chips, nowrap ? styles.chipsNowrap : ''].filter(Boolean).join(' ');

  return (
    <div className={rootClass} role="group" aria-label={label}>
      <span className={styles.srOnly}>{label}</span>
      <div className={chipsClass}>
        {options.map((option) => {
          const active = value === option.value;
          return (
            <Button
              key={option.value || '__all__'}
              type="button"
              size="sm"
              variant={active ? 'solid' : 'outline'}
              onClick={() => onChange(option.value)}
              aria-pressed={active}
            >
              {option.label}
            </Button>
          );
        })}
      </div>
    </div>
  );
}
