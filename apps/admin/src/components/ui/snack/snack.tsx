'use client';

import { useEffect } from 'react';
import { useTranslations } from 'next-intl';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import { Icon } from '../icon';
import styles from './snack.module.css';

export type SnackTone = 'success' | 'error' | 'warning' | 'info' | 'danger';

export type SnackState = {
  tone: SnackTone;
  title: string;
  message: string;
  id?: string;
  /** Optional inline action (e.g. Undo); pressing it also dismisses the snack. */
  action?: {
    label: string;
    onAction: () => void;
  };
  /** Override auto-dismiss delay (ms) — e.g. longer for undoable actions. */
  durationMs?: number;
};

type SnackProps = {
  snack: SnackState | null;
  onClose: () => void;
  durationMs?: number;
};

function isAssertiveSnack(tone: SnackTone) {
  return tone === 'error' || tone === 'danger';
}

function toneIcon(tone: SnackTone): 'check-circle' | 'alert-circle' | 'alert-triangle' | 'info' {
  if (tone === 'success') return 'check-circle';
  if (tone === 'error' || tone === 'danger') return 'alert-circle';
  if (tone === 'warning') return 'alert-triangle';
  return 'info';
}

function toneClassName(tone: SnackTone) {
  if (tone === 'danger') return styles.toneError;
  const key = tone[0].toUpperCase() + tone.slice(1);
  return styles[`tone${key}` as keyof typeof styles];
}

export function Snack({ snack, onClose, durationMs = 3200 }: SnackProps) {
  const t = useTranslations('ui');
  const reducedMotion = useReducedMotion();

  useEffect(() => {
    if (!snack) {
      return undefined;
    }

    const timeoutId = window.setTimeout(() => {
      onClose();
    }, snack.durationMs ?? durationMs);

    return () => window.clearTimeout(timeoutId);
  }, [durationMs, onClose, snack]);

  const assertive = snack ? isAssertiveSnack(snack.tone) : false;

  return (
    <div
      className={styles.viewport}
      aria-live={snack ? (assertive ? 'assertive' : 'polite') : undefined}
      aria-atomic={snack ? true : undefined}
    >
      <AnimatePresence>
        {snack ? (
          <motion.section
            key={snack.id ?? `${snack.tone}-${snack.title}-${snack.message}`}
            className={`${styles.snack} ${toneClassName(snack.tone)}`}
            role={assertive ? 'alert' : 'status'}
            initial={reducedMotion ? { opacity: 1, y: 0, scale: 1 } : { opacity: 0, y: 16, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={reducedMotion ? { opacity: 1, y: 0, scale: 1 } : { opacity: 0, y: 10, scale: 0.98 }}
            transition={{ duration: reducedMotion ? 0 : 0.2, ease: [0.22, 1, 0.36, 1] }}
          >
            <div className={styles.content}>
              <span className={styles.iconWrap} aria-hidden>
                <Icon name={toneIcon(snack.tone)} size={18} />
              </span>
              <div className={styles.textWrap}>
                <p className={styles.title}>{snack.title}</p>
                {snack.message.trim().length > 0 ? (
                  <p className={styles.message}>{snack.message}</p>
                ) : null}
              </div>
              <div className={styles.actions}>
                {snack.action ? (
                  <button
                    type="button"
                    className={styles.actionButton}
                    onClick={() => {
                      snack.action?.onAction();
                      onClose();
                    }}
                  >
                    {snack.action.label}
                  </button>
                ) : null}
                <button
                  type="button"
                  className={styles.closeButton}
                  onClick={onClose}
                  aria-label={t('dismissNotification')}
                >
                  <Icon name="x" size={16} />
                </button>
              </div>
            </div>
          </motion.section>
        ) : null}
      </AnimatePresence>
    </div>
  );
}
