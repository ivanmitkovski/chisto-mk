'use client';

import { useEffect, useRef, useState } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { createPortal } from 'react-dom';
import { Button } from '@/components/ui';
import { Icon } from '@/components/ui';
import styles from './context-detail-modal.module.css';

export type ContextDetailKind = 'submitted' | 'reporter' | 'co-reporters' | 'trust-tier' | 'queue';

type ContextDetailModalProps = {
  isOpen: boolean;
  kind: ContextDetailKind | null;
  /** Report-specific values to display */
  value: string;
  onClose: () => void;
};

function getModalContent(kind: ContextDetailKind, value: string) {
  switch (kind) {
    case 'submitted':
      return {
        title: 'Submitted',
        description: `This report was submitted on ${value}.`,
        body: (
          <p>
            Submission time is recorded when the citizen completes and sends the report. All timestamps use the server
            timezone for consistency across moderators and audit logs.
          </p>
        ),
        icon: 'calendar' as const,
      };
    case 'reporter':
      return {
        title: 'Reporter',
        description: `Report submitted by ${value}.`,
        body: (
          <p>
            Reporter identity is anonymized to protect privacy. The alias shown is used for moderation traceability only.
            Personal details are not visible to moderators.
          </p>
        ),
        icon: 'user' as const,
      };
    case 'co-reporters':
      return {
        title: 'Also reported by',
        description: `Co-reporters: ${value}.`,
        body: (
          <p>
            Multiple citizens reported this same issue. Co-reported issues may indicate higher urgency or community
            concern. Each co-reporter contributes to the report&apos;s visibility in the moderation queue.
          </p>
        ),
        icon: 'users' as const,
      };
    case 'trust-tier':
      return {
        title: 'Trust tier',
        description: `Reporter trust level: ${value}.`,
        body: (
          <p>
            Trust tiers (Bronze, Silver, Gold) reflect the reporter&apos;s verification history and past report quality.
            Higher tiers indicate more established, verified contributors. This helps moderators gauge report reliability.
          </p>
        ),
        icon: 'shield' as const,
      };
    case 'queue':
      return {
        title: 'Queue',
        description: `Current queue: ${value}.`,
        body: (
          <p>
            Reports are organized into queues by urgency, type, or workflow stage. Queues help moderators focus on the
            right batch and ensure SLA targets are met. This report is in the {value} work stream.
          </p>
        ),
        icon: 'scroll-text' as const,
      };
    default:
      return null;
  }
}

export function ContextDetailModal({ isOpen, kind, value, onClose }: ContextDetailModalProps) {
  const [isMounted, setIsMounted] = useState(false);
  const closeButtonRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    const id = requestAnimationFrame(() => {
      requestAnimationFrame(() => setIsMounted(true));
    });
    return () => cancelAnimationFrame(id);
  }, []);

  useEffect(() => {
    if (!isOpen) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    const id = requestAnimationFrame(() => closeButtonRef.current?.focus());
    return () => {
      cancelAnimationFrame(id);
      document.body.style.overflow = prev;
    };
  }, [isOpen]);

  useEffect(() => {
    if (!isOpen) return;
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        onClose();
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [isOpen, onClose]);

  if (!isMounted || typeof document === 'undefined' || !document.body || !kind) {
    return null;
  }

  const content = getModalContent(kind, value);

  return createPortal(
    <AnimatePresence mode="sync">
      {isOpen && content ? (
        <motion.div
          className={styles.backdrop}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.15 }}
          onMouseDown={(e) => {
            if (e.target === e.currentTarget) onClose();
          }}
        >
          <motion.section
            className={styles.modal}
            role="dialog"
            aria-modal="true"
            aria-labelledby="context-detail-title"
            aria-describedby="context-detail-desc"
            initial={{ opacity: 0, y: 8, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 8, scale: 0.98 }}
            transition={{ duration: 0.18, ease: 'easeOut' }}
          >
            <div className={styles.iconRow}>
              <span className={styles.icon} aria-hidden>
                <Icon name={content.icon} size={20} />
              </span>
            </div>
            <header className={styles.header}>
              <h2 id="context-detail-title" className={styles.title}>
                {content.title}
              </h2>
              <p id="context-detail-desc" className={styles.description}>
                {content.description}
              </p>
            </header>
            <div className={styles.body}>{content.body}</div>
            <footer className={styles.footer}>
              <Button ref={closeButtonRef} onClick={onClose}>
                Close
              </Button>
            </footer>
          </motion.section>
        </motion.div>
      ) : null}
    </AnimatePresence>,
    document.body,
  );
}
