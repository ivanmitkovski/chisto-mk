'use client';

import { Icon, Input } from '@/components/ui';
import styles from './search-input.module.css';

export type SearchInputProps = {
  value: string;
  onChange: (value: string) => void;
  onClear?: () => void;
  placeholder?: string;
  'aria-label': string;
  clearLabel: string;
  disabled?: boolean;
  className?: string;
};

export function SearchInput({
  value,
  onChange,
  onClear,
  placeholder,
  'aria-label': ariaLabel,
  clearLabel,
  disabled = false,
  className,
}: SearchInputProps) {
  const fieldClass = [styles.field, className].filter(Boolean).join(' ');

  function handleClear() {
    if (onClear) {
      onClear();
      return;
    }
    onChange('');
  }

  return (
    <Input
      type="text"
      role="searchbox"
      aria-label={ariaLabel}
      placeholder={placeholder}
      value={value}
      disabled={disabled}
      fieldClassName={fieldClass}
      leftSlot={<Icon name="magnifying-glass" size={14} aria-hidden />}
      rightSlot={
        value ? (
          <button
            type="button"
            className={styles.clearBtn}
            onClick={handleClear}
            aria-label={clearLabel}
          >
            <Icon name="x" size={14} aria-hidden />
          </button>
        ) : null
      }
      onChange={(event) => onChange(event.target.value)}
    />
  );
}
