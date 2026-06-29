'use client';

import { useEffect, useMemo, useState } from 'react';
import styles from './news-media-block-editor.module.css';

type NewsVideoPreviewProps = {
  src: string;
  mimeType?: string | null;
  localPreviewSrc?: string | null;
  playbackErrorLabel: string;
  frameClassName: string;
};

export function NewsVideoPreview({
  src,
  mimeType,
  localPreviewSrc,
  playbackErrorLabel,
  frameClassName,
}: NewsVideoPreviewProps) {
  const [remoteFailed, setRemoteFailed] = useState(false);

  useEffect(() => {
    setRemoteFailed(false);
  }, [src, localPreviewSrc]);

  const playbackSrc = useMemo(() => {
    if (localPreviewSrc) return localPreviewSrc;
    if (!remoteFailed) return src;
    return null;
  }, [localPreviewSrc, remoteFailed, src]);

  if (!playbackSrc) {
    return (
      <div className={`${frameClassName} ${styles.videoErrorFrame}`}>
        <p className={styles.videoError}>{playbackErrorLabel}</p>
      </div>
    );
  }

  const useSourceTag = Boolean(mimeType) && !localPreviewSrc;

  return (
    <div className={frameClassName}>
      <video
        key={playbackSrc}
        src={useSourceTag ? undefined : playbackSrc}
        controls
        playsInline
        preload="metadata"
        className={styles.video}
        onError={() => {
          if (localPreviewSrc) return;
          setRemoteFailed(true);
        }}
      >
        {useSourceTag ? <source src={playbackSrc} type={mimeType!} /> : null}
      </video>
    </div>
  );
}
