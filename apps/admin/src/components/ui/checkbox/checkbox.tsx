'use client';

import {
  forwardRef,
  useId,
  type InputHTMLAttributes,
  type ReactNode,
} from 'react';
import { Icon } from '../icon';
import styles from './checkbox.module.css';

export type CheckboxProps = Omit<InputHTMLAttributes<HTMLInputElement>, 'type'> & {
  label?: ReactNode;
  /** Multi-line labels (e.g. duplicate report rows) align to the top of the control. */
  labelAlign?: 'center' | 'start';
};

export const Checkbox = forwardRef<HTMLInputElement, CheckboxProps>(function Checkbox(
  { label, labelAlign = 'center', className, id, disabled, ...rest },
  ref,
) {
  const generatedId = useId();
  const inputId = id ?? generatedId;

  const rootClass = [
    styles.root,
    labelAlign === 'start' ? styles.rootAlignStart : '',
    disabled ? styles.rootDisabled : '',
    className ?? '',
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <label className={rootClass} htmlFor={inputId}>
      <span className={styles.wrap}>
        <input
          ref={ref}
          id={inputId}
          type="checkbox"
          className={styles.input}
          disabled={disabled}
          {...rest}
        />
        <span className={styles.box} aria-hidden>
          <Icon name="check" size={12} className={styles.checkIcon} />
        </span>
      </span>
      {label != null ? <span className={styles.label}>{label}</span> : null}
    </label>
  );
});
