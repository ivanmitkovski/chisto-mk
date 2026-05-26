import Image from 'next/image';
import styles from './avatar.module.css';

type AvatarProps = {
  name: string;
  imageUrl?: string | null;
  size?: 'sm' | 'md' | 'lg';
};

export function Avatar({ name, imageUrl, size = 'md' }: AvatarProps) {
  const initials = name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase())
    .join('');

  if (imageUrl) {
    return (
      <span className={`${styles.avatar} ${styles[size]}`}>
        <Image src={imageUrl} alt="" width={52} height={52} sizes="52px" />
      </span>
    );
  }

  return <span className={`${styles.avatar} ${styles[size]}`}>{initials || '?'}</span>;
}
