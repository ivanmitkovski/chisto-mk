'use client';

import { RefObject, ReactNode } from 'react';
import { useTranslations } from 'next-intl';
import { motion, useReducedMotion } from 'framer-motion';
import { Button, Icon, Input } from '@/components/ui';
import barStyles from './top-bar.module.css';
import styles from './top-bar-header.module.css';

type TopBarHeaderProps = {
  title: string;
  isMobile: boolean;
  isSidebarCollapsed: boolean;
  isMobileSidebarOpen: boolean;
  searchPlaceholder: string;
  shortcutLabel: string;
  searchTriggerRef: RefObject<HTMLInputElement | null>;
  onMenuToggle: () => void;
  onOpenPalette: () => void;
  children: ReactNode;
};

export function TopBarHeader({
  title,
  isMobile,
  isSidebarCollapsed,
  isMobileSidebarOpen,
  searchPlaceholder,
  shortcutLabel,
  searchTriggerRef,
  onMenuToggle,
  onOpenPalette,
  children,
}: TopBarHeaderProps) {
  const t = useTranslations('common');
  const reduceMotion = useReducedMotion();

  const menuIcon = isMobile ? (isMobileSidebarOpen ? 'x' : 'menu') : isSidebarCollapsed ? 'panel-left-open' : 'panel-left-close';
  const menuLabel = isMobile
    ? isMobileSidebarOpen
      ? t('closeMenu')
      : t('openMenu')
    : isSidebarCollapsed
      ? t('expandSidebar')
      : t('collapseSidebar');

  return (
    <motion.header
      className={barStyles.topbar}
      initial={reduceMotion ? false : { opacity: 0, y: -8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: reduceMotion ? 0 : 0.22, ease: 'easeOut' }}
    >
      <div className={styles.titleWrap}>
        <Button
          variant="icon"
          aria-label={menuLabel}
          aria-expanded={isMobile ? isMobileSidebarOpen : undefined}
          className={styles.menuButton}
          onClick={onMenuToggle}
        >
          <Icon name={menuIcon} size={16} />
        </Button>
        <h1 className={styles.title}>{title}</h1>
      </div>
      <div className={styles.actions}>
        <Input
          inputRef={searchTriggerRef}
          aria-label={t('openCommandPalette')}
          placeholder={searchPlaceholder}
          className={styles.searchInput}
          readOnly
          value=""
          data-command-palette-trigger=""
          leftSlot={<Icon name="magnifying-glass" size={14} />}
          rightSlot={<span className={styles.shortcutPill}>{shortcutLabel}</span>}
          onClick={() => onOpenPalette()}
          onKeyDown={(event) => {
            if (event.key === 'Enter' || event.key === ' ') {
              event.preventDefault();
              onOpenPalette();
            }
          }}
        />
        <motion.div
          className={styles.iconCluster}
          initial={reduceMotion ? false : { opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: reduceMotion ? 0 : 0.05, duration: reduceMotion ? 0 : 0.2, ease: 'easeOut' }}
        >
          {children}
        </motion.div>
      </div>
    </motion.header>
  );
}
