import { InputHTMLAttributes, useId } from 'react';
import { Field, fieldDescriptionId } from '../field';
import styles from './date-picker.module.css';

type DatePickerProps = Omit<InputHTMLAttributes<HTMLInputElement>, 'type' | 'size'> & {
  label: string;
  errorText?: string;
};

export function DatePicker({
  id,
  label,
  errorText,
  className,
  required,
  ...rest
}: DatePickerProps) {
  const fallbackId = useId();
  const inputId = id ?? fallbackId;
  const descriptionId = fieldDescriptionId(inputId, errorText);

  return (
    <Field
      label={label}
      htmlFor={inputId}
      errorText={errorText}
      required={required}
      className={styles.field}
    >
      <input
        {...rest}
        id={inputId}
        type="date"
        className={[styles.input, className ?? ''].join(' ').trim()}
        required={required}
        aria-invalid={Boolean(errorText)}
        aria-describedby={descriptionId}
      />
    </Field>
  );
}
