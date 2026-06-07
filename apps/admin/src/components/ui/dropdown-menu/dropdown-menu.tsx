'use client';

import { useEffect, useId, useRef, useState, type ReactNode } from 'react';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import { useMenuKeyboard } from '@/lib/utils/use-menu-keyboard';
import { Icon, type IconName } from '../icon';
import styles from './dropdown-menu.module.css';

const SPRING = { type: 'spring' as const, stiffness: 400, damping: 30 };

export type DropdownMenuProps = {
  label: ReactNode;
  panelAriaLabel: string;
  children: ReactNode;
  icon?: IconName;
  /** Highlights the trigger when any nested option is active. */
  active?: boolean;
  align?: 'start' | 'end';
  /** Icon-only trigger below the map toolbar compact breakpoint. */
  compact?: boolean;
  className?: string;
  triggerClassName?: string;
  'aria-label'?: string;
  /** When false, panel uses role="group" (e.g. checkbox panels). Default: menu keyboard pattern. */
  menuRole?: boolean;
};

export function DropdownMenu({
  label,
  panelAriaLabel,
  children,
  icon,
  active = false,
  align = 'end',
  compact = false,
  className,
  triggerClassName,
  'aria-label': ariaLabel,
  menuRole = true,
}: DropdownMenuProps) {
  const [isOpen, setIsOpen] = useState(false);
  const reducedMotion = useReducedMotion();
  const panelId = useId();
  const containerRef = useRef<HTMLDivElement>(null);
  const panelRef = useRef<HTMLDivElement>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);

  function close() {
    setIsOpen(false);
    triggerRef.current?.focus();
  }

  useMenuKeyboard({
    isOpen: isOpen && menuRole,
    menuRef: panelRef,
    onClose: close,
  });

  useEffect(() => {
    if (!isOpen) return undefined;

    const onPointerDown = (event: PointerEvent) => {
      if (!containerRef.current?.contains(event.target as Node)) {
        close();
      }
    };

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        close();
      }
    };

    window.addEventListener('pointerdown', onPointerDown);
    window.addEventListener('keydown', onKeyDown);
    return () => {
      window.removeEventListener('pointerdown', onPointerDown);
      window.removeEventListener('keydown', onKeyDown);
    };
  }, [isOpen]);

  const rootClass = [styles.dropdownMenu, className].filter(Boolean).join(' ');
  const triggerClass = [
    styles.trigger,
    active ? styles.triggerActive : '',
    compact ? styles.compact : '',
    triggerClassName ?? '',
  ]
    .filter(Boolean)
    .join(' ');
  const panelClass = [styles.panel, align === 'start' ? styles.alignStart : styles.alignEnd]
    .filter(Boolean)
    .join(' ');

  return (
    <div className={rootClass} ref={containerRef}>
      <button
        ref={triggerRef}
        type="button"
        className={triggerClass}
        aria-label={ariaLabel}
        aria-expanded={isOpen}
        aria-haspopup={menuRole ? 'menu' : 'true'}
        aria-controls={panelId}
        onClick={() => setIsOpen((prev) => !prev)}
      >
        {icon ? <Icon name={icon} size={16} aria-hidden /> : null}
        <span className={styles.label}>{label}</span>
        {active ? <span className={styles.activeDot} aria-hidden /> : null}
        <Icon
          name="chevron-down"
          size={14}
          className={`${styles.chevron} ${isOpen ? styles.chevronOpen : ''}`}
          aria-hidden
        />
      </button>
      <AnimatePresence>
        {isOpen ? (
          <motion.div
            ref={panelRef}
            id={panelId}
            role={menuRole ? 'menu' : 'group'}
            aria-label={panelAriaLabel}
            className={panelClass}
            initial={reducedMotion ? false : { opacity: 0, y: -6, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={reducedMotion ? { opacity: 0 } : { opacity: 0, y: -6, scale: 0.98 }}
            transition={reducedMotion ? { duration: 0 } : SPRING}
          >
            {children}
          </motion.div>
        ) : null}
      </AnimatePresence>
    </div>
  );
}
