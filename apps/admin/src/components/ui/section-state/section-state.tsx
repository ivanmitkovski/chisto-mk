import styles from './section-state.module.css';

type SectionStateVariant = 'loading' | 'empty' | 'error';

type SectionStateProps = {
  variant: SectionStateVariant;
  message: string;
};

export function SectionState({ variant, message }: SectionStateProps) {
  const className = [
    styles.state,
    variant === 'loading' ? styles.loading : '',
    variant === 'error' ? styles.error : '',
  ]
    .join(' ')
    .trim();

  return <p className={className}>{message}</p>;
}
