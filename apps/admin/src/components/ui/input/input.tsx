import { InputHTMLAttributes, ReactNode, RefObject, useId } from 'react';
import { Field, fieldDescriptionId } from '../field';
import styles from './input.module.css';

export type InputProps = Omit<InputHTMLAttributes<HTMLInputElement>, 'size'> & {
  label?: string | undefined;
  helperText?: string | undefined;
  errorText?: string | undefined;
  leftSlot?: ReactNode | undefined;
  rightSlot?: ReactNode | undefined;
  inputRef?: RefObject<HTMLInputElement | null> | undefined;
};

export function Input({
  id,
  label,
  helperText,
  errorText,
  leftSlot,
  rightSlot,
  inputRef,
  className,
  required,
  ...rest
}: InputProps) {
  const fallbackId = useId();
  const inputId = id ?? fallbackId;
  const hasError = Boolean(errorText);
  const descriptionId = fieldDescriptionId(inputId, errorText, helperText);

  const inputClassName = [
    styles.input,
    leftSlot ? styles.withLeftSlot : '',
    rightSlot ? styles.withRightSlot : '',
    hasError ? styles.error : '',
    className ?? '',
  ]
    .join(' ')
    .trim();

  return (
    <Field
      label={label}
      htmlFor={inputId}
      helperText={helperText}
      errorText={errorText}
      required={required}
    >
      <div className={styles.inputWrap}>
        {leftSlot ? <span className={styles.leftSlot}>{leftSlot}</span> : null}
        <input
          {...rest}
          id={inputId}
          ref={inputRef}
          className={inputClassName}
          required={required}
          aria-invalid={hasError}
          aria-describedby={descriptionId}
        />
        {rightSlot ? <span className={styles.rightSlot}>{rightSlot}</span> : null}
      </div>
    </Field>
  );
}
