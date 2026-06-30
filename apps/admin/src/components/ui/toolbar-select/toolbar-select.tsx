import type { SelectHTMLAttributes } from 'react';
import styles from './toolbar-select.module.css';

export type ToolbarSelectOption = {
  value: string;
  label: string;
};

export type ToolbarSelectProps = Omit<SelectHTMLAttributes<HTMLSelectElement>, 'children'> & {
  options: readonly ToolbarSelectOption[];
};

export function ToolbarSelect({ options, className, ...rest }: ToolbarSelectProps) {
  const selectClass = [styles.select, className].filter(Boolean).join(' ');

  return (
    <select className={selectClass} {...rest}>
      {options.map((option) => (
        <option key={option.value || '_'} value={option.value}>
          {option.label}
        </option>
      ))}
    </select>
  );
}
