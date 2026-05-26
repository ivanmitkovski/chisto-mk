import { InputHTMLAttributes } from 'react';
import styles from './date-picker.module.css';

type DatePickerProps = Omit<InputHTMLAttributes<HTMLInputElement>, 'type' | 'size'> & {
  label: string;
  errorText?: string;
};

export function DatePicker({ id, label, errorText, className, ...rest }: DatePickerProps) {
  return (
    <label className={styles.field} htmlFor={id}>
      <span className={styles.label}>{label}</span>
      <input
        {...rest}
        id={id}
        type="date"
        className={[styles.input, className ?? ''].join(' ').trim()}
        aria-invalid={Boolean(errorText)}
        aria-describedby={errorText ? `${id}-error` : undefined}
      />
      {errorText ? (
        <span id={`${id}-error`} className={styles.error}>
          {errorText}
        </span>
      ) : null}
    </label>
  );
}
