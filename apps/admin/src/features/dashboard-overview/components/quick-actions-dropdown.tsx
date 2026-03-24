'use client';

import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import type { IconName } from '@/components/ui';
import { Icon } from '@/components/ui';
import styles from './quick-actions-dropdown.module.css';

type QuickAction = {
  href: string;
  label: string;
  icon: IconName;
};

const ACTIONS: QuickAction[] = [
  { href: '/dashboard/reports?status=NEW', label: 'New reports', icon: 'document-text' },
  { href: '/dashboard/reports?status=IN_REVIEW', label: 'In review', icon: 'document-forward' },
  { href: '/dashboard/users', label: 'Users', icon: 'users' },
  { href: '/dashboard/sites', label: 'Sites', icon: 'location' },
  { href: '/dashboard/events', label: 'Events', icon: 'calendar' },
  { href: '/dashboard/audit', label: 'Audit log', icon: 'scroll-text' },
];

const SPRING = { type: 'spring' as const, stiffness: 400, damping: 30 };

export function QuickActionsDropdown() {
  const [isOpen, setIsOpen] = useState(false);
  const reducedMotion = useReducedMotion();
  const containerRef = useRef<HTMLDivElement>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);

  function close() {
    setIsOpen(false);
  }

  useEffect(() => {
    if (!isOpen) return;

    const onPointerDown = (e: PointerEvent) => {
      const target = e.target as Node;
      if (containerRef.current?.contains(target) || triggerRef.current?.contains(target)) return;
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
        aria-label="Quick actions menu"
        onClick={() => setIsOpen((prev) => !prev)}
        {...(reducedMotion ? {} : { whileTap: { scale: 0.98 }, transition: SPRING })}
      >
        <Icon name="menu" size={16} className={styles.triggerIcon} aria-hidden />
        <span>Quick actions</span>
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
            role="menu"
            aria-label="Quick actions"
            className={styles.panel}
            initial={
              reducedMotion ? false : { opacity: 0, y: -6, scale: 0.98 }
            }
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={reducedMotion ? { opacity: 0 } : { opacity: 0, y: -6, scale: 0.98 }}
            transition={reducedMotion ? { duration: 0 } : SPRING}
          >
            <ul className={styles.list}>
              {ACTIONS.map((action, i) => (
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
