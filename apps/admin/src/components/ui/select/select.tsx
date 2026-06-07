import { SelectHTMLAttributes, useId } from 'react';
import { Field, fieldDescriptionId } from '../field';
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

export function Select({
  id,
  label,
  options,
  errorText,
  helperText,
  className,
  required,
  ...rest
}: SelectProps) {
  const fallbackId = useId();
  const selectId = id ?? fallbackId;
  const descriptionId = fieldDescriptionId(selectId, errorText, helperText);

  return (
    <Field
      label={label}
      htmlFor={selectId}
      errorText={errorText}
      helperText={helperText}
      required={required}
      className={styles.field}
    >
      <select
        {...rest}
        id={selectId}
        className={[styles.select, className ?? ''].join(' ').trim()}
        required={required}
        aria-invalid={Boolean(errorText)}
        aria-describedby={descriptionId}
      >
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
    </Field>
  );
}
