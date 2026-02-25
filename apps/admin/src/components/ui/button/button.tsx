import { ButtonHTMLAttributes } from 'react';
import styles from './button.module.css';

type ButtonVariant = 'solid' | 'outline' | 'ghost' | 'icon';
type ButtonSize = 'sm' | 'md';

export type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: ButtonVariant;
  size?: ButtonSize;
  isLoading?: boolean;
  fullWidth?: boolean;
};

const variantClassByName: Record<ButtonVariant, string> = {
  solid: styles.variantSolid,
  outline: styles.variantOutline,
  ghost: styles.variantGhost,
  icon: styles.variantIcon,
};

const sizeClassByName: Record<ButtonSize, string> = {
  sm: styles.sizeSm,
  md: styles.sizeMd,
};

export function Button({
  variant = 'solid',
  size = 'md',
  isLoading = false,
  fullWidth = false,
  className,
  disabled,
  type,
  children,
  ...rest
}: ButtonProps) {
  const resolvedClassName = [
    styles.button,
    variantClassByName[variant],
    sizeClassByName[size],
    fullWidth ? styles.fullWidth : '',
    isLoading ? styles.loading : '',
    className ?? '',
  ]
    .join(' ')
    .trim();

  return (
    <button {...rest} type={type ?? 'button'} className={resolvedClassName} disabled={disabled || isLoading}>
      {isLoading ? 'Working...' : children}
    </button>
  );
}
