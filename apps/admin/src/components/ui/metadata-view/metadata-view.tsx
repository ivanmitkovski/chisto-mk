import { formatMetadataValue } from './format-metadata';
import styles from './metadata-view.module.css';

type MetadataViewProps = {
  value: unknown;
  /** Compact single-line cell preview vs expanded pre block */
  variant?: 'compact' | 'block';
  className?: string;
};

export function MetadataView({ value, variant = 'block', className }: MetadataViewProps) {
  const text = formatMetadataValue(value, variant === 'block');

  if (variant === 'compact') {
    return (
      <span className={[styles.root, styles.compact, className].filter(Boolean).join(' ')} title={text}>
        {text}
      </span>
    );
  }

  return (
    <pre className={[styles.root, styles.block, className].filter(Boolean).join(' ')}>{text}</pre>
  );
}

export { formatMetadataValue } from './format-metadata';
