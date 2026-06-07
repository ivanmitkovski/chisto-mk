'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { motion, useReducedMotion } from 'framer-motion';
import { Brand, Button, Icon } from '@/components/ui';
import { useNavItemLabel } from '@/lib/i18n';
import { NavItem } from '../types';
import styles from './sidebar-nav.module.css';

type SidebarNavProps = {
  items: ReadonlyArray<NavItem>;
  activeItem: NavItem['key'];
  isCollapsed: boolean;
  isMobile: boolean;
  isMobileOpen: boolean;
  onRequestClose: () => void;
  onToggleCollapse: () => void;
};

function NavLink({
  item,
  activeItem,
  isCollapsed,
  isMobile,
  onRequestClose,
  onPrefetch,
}: {
  item: NavItem;
  activeItem: NavItem['key'];
  isCollapsed: boolean;
  isMobile: boolean;
  onRequestClose: () => void;
  onPrefetch: (href: string) => void;
}) {
  const label = useNavItemLabel(item.labelKey ?? item.key);
  const reduceMotion = useReducedMotion();

  return (
    <motion.div
      transition={{ duration: reduceMotion ? 0 : 0.15 }}
      {...(!reduceMotion ? { whileHover: { x: 2 } } : {})}
    >
      <Link
        href={item.href}
        className={`${styles.navLink} ${item.key === activeItem ? styles.navLinkActive : ''}`}
        aria-current={item.key === activeItem ? 'page' : undefined}
        onPointerEnter={() => onPrefetch(item.href)}
        {...(isCollapsed ? { 'aria-label': label } : {})}
        {...(isMobile ? { onClick: onRequestClose } : {})}
      >
        <span className={styles.navIconWrap}>
          <Icon name={item.icon} className={styles.navIcon} />
        </span>
        <span className={styles.navLabel}>{label}</span>
      </Link>
    </motion.div>
  );
}

export function SidebarNav({
  items,
  activeItem,
  isCollapsed,
  isMobile,
  isMobileOpen,
  onRequestClose,
  onToggleCollapse,
}: SidebarNavProps) {
  const router = useRouter();
  const t = useTranslations('common');
  const asideClassName = [
    styles.sidebar,
    isCollapsed ? styles.sidebarCollapsed : '',
    isMobile ? styles.sidebarMobile : '',
    isMobile && isMobileOpen ? styles.sidebarMobileOpen : '',
  ]
    .join(' ')
    .trim();
  const brandClassName = isCollapsed ? styles.brandCompact : '';

  return (
    <aside className={asideClassName} aria-label={t('sidebarMenu')} data-open={isMobileOpen}>
      <div className={styles.brandRow}>
        <div className={styles.brandWrap}>
          <Brand priority compact={isCollapsed} className={brandClassName} />
        </div>
        {isMobile ? (
          <Button variant="icon" aria-label={t('closeMenu')} className={styles.mobileCloseButton} onClick={onRequestClose}>
            <Icon name="x" size={16} />
          </Button>
        ) : null}
      </div>

      <div className={styles.navScroll}>
        <nav className={styles.nav} aria-label={t('primaryNavigation')}>
          {items.map((item) => (
            <NavLink
              key={item.key}
              item={item}
              activeItem={activeItem}
              isCollapsed={isCollapsed}
              isMobile={isMobile}
              onRequestClose={onRequestClose}
              onPrefetch={(href) => router.prefetch(href)}
            />
          ))}
        </nav>
      </div>
      {!isMobile ? (
        <div className={styles.footer}>
          <Button variant="ghost" className={styles.collapseButton} onClick={onToggleCollapse} aria-label={t('toggleSidebarWidth')}>
            <Icon name={isCollapsed ? 'panel-left-open' : 'panel-left-close'} size={15} />
            <span className={styles.collapseText}>{isCollapsed ? t('expandMenu') : t('collapseMenu')}</span>
          </Button>
        </div>
      ) : null}
    </aside>
  );
}
