'use client';

import { useEffect } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { AlertCircle, CheckCircle2, Info, TriangleAlert, X } from 'lucide-react';
import styles from './snack.module.css';

export type SnackTone = 'success' | 'error' | 'warning' | 'info';

export type SnackState = {
  tone: SnackTone;
  title: string;
  message: string;
};

type SnackProps = {
  snack: SnackState | null;
  onClose: () => void;
  durationMs?: number;
};

function toneIcon(tone: SnackTone) {
  if (tone === 'success') {
    return CheckCircle2;
  }

  if (tone === 'error') {
    return AlertCircle;
  }

  if (tone === 'warning') {
    return TriangleAlert;
  }

  return Info;
}

export function Snack({ snack, onClose, durationMs = 3200 }: SnackProps) {
  useEffect(() => {
    if (!snack) {
      return undefined;
    }

    const timeoutId = window.setTimeout(() => {
      onClose();
    }, durationMs);

    return () => window.clearTimeout(timeoutId);
  }, [durationMs, onClose, snack]);

  return (
    <div className={styles.viewport} aria-live="polite" aria-atomic>
      <AnimatePresence>
        {snack ? (
          <motion.section
            key={`${snack.tone}-${snack.title}-${snack.message}`}
            className={`${styles.snack} ${styles[`tone${snack.tone[0].toUpperCase()}${snack.tone.slice(1)}`]}`}
            role={snack.tone === 'error' ? 'alert' : 'status'}
            initial={{ opacity: 0, y: 16, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 10, scale: 0.98 }}
            transition={{ duration: 0.2 }}
          >
            <div className={styles.content}>
              <span className={styles.iconWrap} aria-hidden>
                {(() => {
                  const IconComponent = toneIcon(snack.tone);
                  return <IconComponent size={16} />;
                })()}
              </span>
              <div className={styles.textWrap}>
                <p className={styles.title}>{snack.title}</p>
                <p className={styles.message}>{snack.message}</p>
              </div>
              <button type="button" className={styles.closeButton} onClick={onClose} aria-label="Dismiss notification">
                <X size={16} />
              </button>
            </div>
          </motion.section>
        ) : null}
      </AnimatePresence>
    </div>
  );
}
