import Image from 'next/image';
import styles from './brand.module.css';

type BrandProps = {
  compact?: boolean;
  className?: string;
  priority?: boolean;
};

export function Brand({ compact = false, className, priority = false }: BrandProps) {
  const rootClassName = [styles.root, compact ? styles.compact : '', className ?? ''].join(' ').trim();

  return (
    <div className={rootClassName}>
      <Image
        src="/brand/chisto-mk-logo.svg"
        alt="Chisto.mk logo"
        width={28}
        height={32}
        className={styles.logo}
        priority={priority}
      />
      <span className={styles.text}>
        Chisto.<span className={styles.accent}>mk</span>
      </span>
    </div>
  );
}
