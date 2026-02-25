'use client';

import { motion } from 'framer-motion';
import { Button, Icon, Input } from '@/components/ui';
import styles from './top-bar.module.css';

type TopBarProps = {
  title: string;
  isMobile: boolean;
  isSidebarCollapsed: boolean;
  isMobileSidebarOpen: boolean;
  onMenuToggle: () => void;
};

export function TopBar({
  title,
  isMobile,
  isSidebarCollapsed,
  isMobileSidebarOpen,
  onMenuToggle,
}: TopBarProps) {
  const menuIcon = isMobile ? (isMobileSidebarOpen ? 'x' : 'menu') : isSidebarCollapsed ? 'panel-left-open' : 'panel-left-close';
  const menuLabel = isMobile
    ? isMobileSidebarOpen
      ? 'Close menu'
      : 'Open menu'
    : isSidebarCollapsed
      ? 'Expand sidebar'
      : 'Collapse sidebar';

  return (
    <motion.header
      className={styles.topbar}
      initial={{ opacity: 0, y: -8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.22 }}
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
          aria-label="Search dashboard"
          placeholder="Search reports"
          className={styles.searchInput}
          leftSlot={<Icon name="magnifying-glass" size={14} />}
        />
        <motion.div className={styles.iconCluster} initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.05 }}>
          <motion.span className={styles.notifyWrap} whileHover={{ y: -1 }}>
            <Button variant="icon" aria-label="Notifications" className={styles.iconButton}>
              <Icon name="notification-bing" size={16} />
            </Button>
            <span className={styles.notifyDot} aria-hidden />
          </motion.span>
          <motion.span whileHover={{ y: -1 }}>
            <Button variant="icon" aria-label="Profile" className={styles.profileButton}>
              <Icon name="user" size={16} />
            </Button>
          </motion.span>
        </motion.div>
      </div>
    </motion.header>
  );
}
