'use client';

import Link from 'next/link';
import { motion } from 'framer-motion';
import { Brand, Button, Icon } from '@/components/ui';
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

export function SidebarNav({
  items,
  activeItem,
  isCollapsed,
  isMobile,
  isMobileOpen,
  onRequestClose,
  onToggleCollapse,
}: SidebarNavProps) {
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
    <aside className={asideClassName} aria-label="Sidebar menu" data-open={isMobileOpen}>
      <div className={styles.brandRow}>
        <div className={styles.brandWrap}>
          <Brand priority compact={isCollapsed} className={brandClassName} />
        </div>
        {isMobile ? (
          <Button variant="icon" aria-label="Close menu" className={styles.mobileCloseButton} onClick={onRequestClose}>
            <Icon name="x" size={16} />
          </Button>
        ) : null}
      </div>

      <nav className={styles.nav}>
        {items.map((item) => (
          <motion.div key={item.key} whileHover={{ x: 2 }} transition={{ duration: 0.15 }}>
            <Link
              href={item.href}
              className={`${styles.navLink} ${item.key === activeItem ? styles.navLinkActive : ''}`}
              aria-current={item.key === activeItem ? 'page' : undefined}
              {...(isMobile ? { onClick: onRequestClose } : {})}
            >
              <span className={styles.navIconWrap}>
                <Icon name={item.icon} className={styles.navIcon} />
              </span>
              <span className={styles.navLabel}>{item.label}</span>
            </Link>
          </motion.div>
        ))}
      </nav>
      {!isMobile ? (
        <div className={styles.footer}>
          <Button variant="ghost" className={styles.collapseButton} onClick={onToggleCollapse} aria-label="Toggle sidebar width">
            <Icon name={isCollapsed ? 'panel-left-open' : 'panel-left-close'} size={15} />
            <span className={styles.collapseText}>{isCollapsed ? 'Expand menu' : 'Collapse menu'}</span>
          </Button>
        </div>
      ) : null}
    </aside>
  );
}
