import { SelectHTMLAttributes } from 'react';
import { InputProps } from '../input';
import styles from './select.module.css';

type SelectOption = {
  value: string;
  label: string;
};

type SelectProps = Omit<SelectHTMLAttributes<HTMLSelectElement>, 'size'> & {
  label: string;
  options: SelectOption[];
  errorText?: InputProps['errorText'];
  helperText?: InputProps['helperText'];
};

export function Select({ id, label, options, errorText, helperText, className, ...rest }: SelectProps) {
  const descriptionId = errorText ? `${id}-error` : helperText ? `${id}-help` : undefined;
  return (
    <label className={styles.field} htmlFor={id}>
      <span className={styles.label}>{label}</span>
      <select
        {...rest}
        id={id}
        className={[styles.select, className ?? ''].join(' ').trim()}
        aria-invalid={Boolean(errorText)}
        aria-describedby={descriptionId}
      >
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
      {errorText ? (
        <span id={`${id}-error`} className={styles.error}>
          {errorText}
        </span>
      ) : helperText ? (
        <span id={`${id}-help`} className={styles.helper}>
          {helperText}
        </span>
      ) : null}
    </label>
  );
}
