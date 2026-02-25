import { InputHTMLAttributes, ReactNode, RefObject, useId } from 'react';
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
  ...rest
}: InputProps) {
  const fallbackId = useId();
  const inputId = id ?? fallbackId;
  const hasError = Boolean(errorText);
  const descriptionId = hasError ? `${inputId}-error` : helperText ? `${inputId}-help` : undefined;

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
    <div className={styles.field}>
      {label ? (
        <label className={styles.label} htmlFor={inputId}>
          {label}
        </label>
      ) : null}
      <div className={styles.inputWrap}>
        {leftSlot ? <span className={styles.leftSlot}>{leftSlot}</span> : null}
        <input
          {...rest}
          id={inputId}
          ref={inputRef}
          className={inputClassName}
          aria-invalid={hasError}
          aria-describedby={descriptionId}
        />
        {rightSlot ? <span className={styles.rightSlot}>{rightSlot}</span> : null}
      </div>
      {hasError ? (
        <p id={`${inputId}-error`} className={`${styles.message} ${styles.messageError}`}>
          {errorText}
        </p>
      ) : helperText ? (
        <p id={`${inputId}-help`} className={styles.message}>
          {helperText}
        </p>
      ) : null}
    </div>
  );
}
