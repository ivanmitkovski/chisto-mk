import styles from './spinner.module.css';

type SpinnerSize = 'sm' | 'md' | 'lg';

type SpinnerProps = {
  size?: SpinnerSize;
  /** Use when spinner is on a dark/primary background (e.g. solid green button) */
  inverted?: boolean;
  /** Optional label for screen readers when used standalone */
  'aria-label'?: string;
  className?: string;
};

const sizeClassByName: Record<SpinnerSize, string> = {
  sm: styles.sizeSm,
  md: styles.sizeMd,
  lg: styles.sizeLg,
};

export function Spinner({
  size = 'md',
  inverted = false,
  'aria-label': ariaLabel,
  className = '',
}: SpinnerProps) {
  const resolvedClassName = [
    styles.spinner,
    sizeClassByName[size],
    inverted ? styles.inverted : '',
    className,
  ]
    .join(' ')
    .trim();

  const isDecorative = ariaLabel === undefined;

  return (
    <span
      role={isDecorative ? undefined : 'status'}
      aria-label={isDecorative ? undefined : ariaLabel}
      aria-hidden={isDecorative ? true : undefined}
      className={resolvedClassName}
    />
  );
}
