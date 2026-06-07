'use client';

import { useEffect, useId, useMemo, useRef, useState } from 'react';
import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import type { IconName } from '@/components/ui';
import { Icon } from '@/components/ui';
import { useMenuKeyboard } from '@/lib/utils/use-menu-keyboard';
import styles from './quick-actions-dropdown.module.css';

type QuickAction = {
  href: string;
  labelKey: string;
  icon: IconName;
};

const ACTION_CONFIG: QuickAction[] = [
  { href: '/dashboard/reports?status=NEW', labelKey: 'newReports', icon: 'document-text' },
  { href: '/dashboard/reports?status=IN_REVIEW', labelKey: 'inReview', icon: 'document-forward' },
  { href: '/dashboard/users', labelKey: 'users', icon: 'users' },
  { href: '/dashboard/sites', labelKey: 'sites', icon: 'location' },
  { href: '/dashboard/events', labelKey: 'events', icon: 'calendar' },
  { href: '/dashboard/audit', labelKey: 'auditLog', icon: 'scroll-text' },
];

const SPRING = { type: 'spring' as const, stiffness: 400, damping: 30 };

export function QuickActionsDropdown() {
  const t = useTranslations('dashboard.quickActions');
  const actions = useMemo(
    () => ACTION_CONFIG.map((action) => ({ ...action, label: t(action.labelKey) })),
    [t],
  );
  const [isOpen, setIsOpen] = useState(false);
  const reducedMotion = useReducedMotion();
  const panelId = useId();
  const containerRef = useRef<HTMLDivElement>(null);
  const panelRef = useRef<HTMLElement>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);

  function close() {
    setIsOpen(false);
    triggerRef.current?.focus();
  }

  useMenuKeyboard({
    isOpen,
    menuRef: panelRef,
    onClose: close,
  });

  useEffect(() => {
    if (!isOpen) return;

    const onPointerDown = (e: PointerEvent) => {
      const target = e.target as Node;
      if (containerRef.current?.contains(target)) return;
      close();
    };

    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') close();
    };

    window.addEventListener('pointerdown', onPointerDown);
    window.addEventListener('keydown', onKeyDown);
    return () => {
      window.removeEventListener('pointerdown', onPointerDown);
      window.removeEventListener('keydown', onKeyDown);
    };
  }, [isOpen]);

  return (
    <div className={styles.wrapper} ref={containerRef}>
      <motion.button
        ref={triggerRef}
        type="button"
        className={styles.trigger}
        aria-expanded={isOpen}
        aria-haspopup="menu"
        aria-controls={panelId}
        aria-label={t('menuAria')}
        onClick={() => setIsOpen((prev) => !prev)}
        {...(reducedMotion ? {} : { whileTap: { scale: 0.98 }, transition: SPRING })}
      >
        <Icon name="menu" size={16} className={styles.triggerIcon} aria-hidden />
        <span>{t('title')}</span>
        <Icon
          name="chevron-down"
          size={14}
          className={`${styles.chevron} ${isOpen ? styles.chevronOpen : ''}`}
          aria-hidden
        />
      </motion.button>
      <AnimatePresence>
        {isOpen ? (
          <motion.nav
            ref={panelRef}
            id={panelId}
            role="menu"
            aria-label={t('panelAria')}
            className={styles.panel}
            initial={
              reducedMotion ? false : { opacity: 0, y: -6, scale: 0.98 }
            }
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={reducedMotion ? { opacity: 0 } : { opacity: 0, y: -6, scale: 0.98 }}
            transition={reducedMotion ? { duration: 0 } : SPRING}
          >
            <ul className={styles.list}>
              {actions.map((action, i) => (
                <motion.li
                  key={action.href}
                  initial={reducedMotion ? false : { opacity: 0, x: -4 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={
                    reducedMotion
                      ? { duration: 0 }
                      : { ...SPRING, delay: 0.03 + i * 0.03 }
                  }
                >
                  <Link
                    href={action.href}
                    className={styles.item}
                    role="menuitem"
                    tabIndex={-1}
                    onClick={close}
                  >
                    <Icon name={action.icon} size={15} className={styles.itemIcon} aria-hidden />
                    {action.label}
                    <Icon name="chevron-right" size={12} className={styles.itemChevron} aria-hidden />
                  </Link>
                </motion.li>
              ))}
            </ul>
          </motion.nav>
        ) : null}
      </AnimatePresence>
    </div>
  );
}
