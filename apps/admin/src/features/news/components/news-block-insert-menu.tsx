'use client';

import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import { useEffect, useId, useRef, useState } from 'react';
import { Icon } from '@/components/ui';
import type { IconName } from '@/components/ui';
import { useMenuKeyboard } from '@/lib/utils/use-menu-keyboard';
import type { InsertIconTone } from '../lib/news-block-insert-config';
import styles from './news-block-insert-menu.module.css';

const SPRING = { type: 'spring' as const, stiffness: 420, damping: 32 };

export type NewsBlockInsertMenuItem = {
  id: string;
  icon: IconName;
  tone: InsertIconTone;
  label: string;
  description: string;
  hint?: string | undefined;
  disabled?: boolean | undefined;
  onSelect: () => void;
};

export type NewsBlockInsertMenuSection = {
  id: string;
  label: string;
  items: NewsBlockInsertMenuItem[];
};

type NewsBlockInsertMenuPanelProps = {
  open: boolean;
  sections: NewsBlockInsertMenuSection[];
  ariaLabel: string;
  panelRef: React.RefObject<HTMLDivElement | null>;
  className?: string;
  align?: 'start' | 'center' | 'end';
  filterQuery?: string | undefined;
  filterPlaceholder?: string | undefined;
  emptyLabel?: string | undefined;
  onFilterChange?: ((query: string) => void) | undefined;
  onClose?: () => void;
};

function toneClass(tone: InsertIconTone): string {
  switch (tone) {
    case 'media':
      return styles.iconMedia;
    case 'advanced':
      return styles.iconAdvanced;
    default:
      return styles.iconText;
  }
}

type ScrollEdges = {
  canScrollUp: boolean;
  canScrollDown: boolean;
};

function readScrollEdges(element: HTMLElement | null): ScrollEdges {
  if (!element) {
    return { canScrollUp: false, canScrollDown: false };
  }
  const { scrollTop, clientHeight, scrollHeight } = element;
  const overflow = scrollHeight - clientHeight > 1;
  return {
    canScrollUp: overflow && scrollTop > 1,
    canScrollDown: overflow && scrollTop + clientHeight < scrollHeight - 1,
  };
}

export function NewsBlockInsertMenuPanel({
  open,
  sections,
  ariaLabel,
  panelRef,
  className,
  align = 'start',
  filterQuery,
  filterPlaceholder,
  emptyLabel,
  onFilterChange,
  onClose,
}: NewsBlockInsertMenuPanelProps) {
  const reducedMotion = useReducedMotion();
  const panelId = useId();
  const scrollRef = useRef<HTMLDivElement>(null);
  const [scrollEdges, setScrollEdges] = useState<ScrollEdges>({
    canScrollUp: false,
    canScrollDown: false,
  });

  useMenuKeyboard({
    isOpen: open,
    menuRef: panelRef,
    onClose: onClose ?? (() => {}),
  });

  useEffect(() => {
    if (!open) {
      setScrollEdges({ canScrollUp: false, canScrollDown: false });
      return undefined;
    }

    const scrollEl = scrollRef.current;
    if (!scrollEl) return undefined;

    const syncScrollEdges = () => {
      setScrollEdges(readScrollEdges(scrollEl));
    };

    syncScrollEdges();
    scrollEl.addEventListener('scroll', syncScrollEdges, { passive: true });
    const resizeObserver = new ResizeObserver(syncScrollEdges);
    resizeObserver.observe(scrollEl);

    return () => {
      scrollEl.removeEventListener('scroll', syncScrollEdges);
      resizeObserver.disconnect();
    };
  }, [open, sections]);

  const wrapClass = [
    styles.panelWrap,
    align === 'center' ? styles.wrapCenter : '',
    align === 'end' ? styles.wrapEnd : '',
  ]
    .filter(Boolean)
    .join(' ');

  const panelClass = [styles.panel, className ?? ''].filter(Boolean).join(' ');

  return (
    <AnimatePresence>
      {open ? (
        <div className={wrapClass}>
          <motion.div
            ref={panelRef}
            id={panelId}
            role="menu"
            aria-label={ariaLabel}
            className={panelClass}
            initial={reducedMotion ? false : { opacity: 0, y: -6, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={reducedMotion ? { opacity: 0 } : { opacity: 0, y: -6, scale: 0.98 }}
            transition={reducedMotion ? { duration: 0 } : SPRING}
            data-scroll-top={scrollEdges.canScrollUp ? 'true' : 'false'}
            data-scroll-bottom={scrollEdges.canScrollDown ? 'true' : 'false'}
          >
            <div className={styles.scrollFadeTop} aria-hidden />
            <div className={styles.scrollFadeBottom} aria-hidden />
            <div ref={scrollRef} className={styles.panelScroll}>
              {onFilterChange ? (
                <div className={styles.filterRow}>
                  <input
                    type="search"
                    className={styles.filterInput}
                    value={filterQuery ?? ''}
                    placeholder={filterPlaceholder}
                    aria-label={filterPlaceholder}
                    onChange={(event) => onFilterChange(event.target.value)}
                  />
                </div>
              ) : null}
              {sections.length === 0 && emptyLabel ? (
                <p className={styles.empty}>{emptyLabel}</p>
              ) : null}
              {sections.map((section, sectionIndex) => (
                <div key={section.id} className={styles.section}>
                  <p className={styles.sectionLabel}>{section.label}</p>
                  <ul className={styles.itemList}>
                    {section.items.map((item) => (
                      <li key={item.id}>
                        <button
                          type="button"
                          role="menuitem"
                          className={styles.item}
                          disabled={item.disabled}
                          onClick={item.onSelect}
                        >
                          <span className={`${styles.iconWrap} ${toneClass(item.tone)}`}>
                            <Icon name={item.icon} size={16} strokeWidth={1.75} />
                          </span>
                          <span className={styles.itemBody}>
                            <span className={styles.itemLabel}>{item.label}</span>
                            <span className={styles.itemDescription}>{item.description}</span>
                            {item.hint ? <span className={styles.itemHint}>{item.hint}</span> : null}
                          </span>
                        </button>
                      </li>
                    ))}
                  </ul>
                  {sectionIndex < sections.length - 1 ? (
                    <div className={styles.sectionDivider} aria-hidden />
                  ) : null}
                </div>
              ))}
            </div>
          </motion.div>
        </div>
      ) : null}
    </AnimatePresence>
  );
}
