'use client';

import Image from 'next/image';
import { useState } from 'react';
import styles from './avatar.module.css';

type AvatarProps = {
  name: string;
  imageUrl?: string | null;
  size?: 'sm' | 'md' | 'lg';
};

const SIZE_PX: Record<NonNullable<AvatarProps['size']>, number> = {
  sm: 32,
  md: 40,
  lg: 52,
};

export function Avatar({ name, imageUrl, size = 'md' }: AvatarProps) {
  const [imageFailed, setImageFailed] = useState(false);
  const initials = name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase())
    .join('');
  const dimension = SIZE_PX[size];
  const showImage = Boolean(imageUrl) && !imageFailed;

  if (showImage && imageUrl) {
    return (
      <span className={`${styles.avatar} ${styles[size]}`}>
        <Image
          src={imageUrl}
          alt=""
          width={dimension}
          height={dimension}
          sizes={`${dimension}px`}
          onError={() => setImageFailed(true)}
        />
      </span>
    );
  }

  return <span className={`${styles.avatar} ${styles[size]}`}>{initials || '?'}</span>;
}
