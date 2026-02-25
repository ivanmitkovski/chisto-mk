'use client';

import { ReactNode, useEffect, useState } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { adminNavigation } from '../config/navigation';
import { NavItemKey } from '../types';
import { SidebarNav } from './sidebar-nav';
import { TopBar } from './top-bar';
import styles from './admin-shell.module.css';

type AdminShellProps = {
  title: string;
  activeItem: NavItemKey;
  children: ReactNode;
};

const DESKTOP_SIDEBAR_KEY = 'chisto-admin-sidebar-collapsed';

export function AdminShell({ title, activeItem, children }: AdminShellProps) {
  const [isMobile, setIsMobile] = useState(false);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);
  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState(false);

  useEffect(() => {
    const mediaQuery = window.matchMedia('(max-width: 48rem)');

    const applyState = (matches: boolean) => {
      setIsMobile(matches);
    };

    applyState(mediaQuery.matches);

    const onChange = (event: MediaQueryListEvent) => applyState(event.matches);
    mediaQuery.addEventListener('change', onChange);

    return () => mediaQuery.removeEventListener('change', onChange);
  }, []);

  useEffect(() => {
    const persistedValue = window.localStorage.getItem(DESKTOP_SIDEBAR_KEY);
    setIsSidebarCollapsed(persistedValue === '1');
  }, []);

  useEffect(() => {
    if (!isMobile) {
      return;
    }

    setIsMobileSidebarOpen(false);
  }, [isMobile, activeItem]);

  useEffect(() => {
    if (!isMobile || !isMobileSidebarOpen) {
      document.body.style.overflow = '';
      return;
    }

    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = '';
    };
  }, [isMobile, isMobileSidebarOpen]);

  useEffect(() => {
    if (!isMobileSidebarOpen) {
      return;
    }

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setIsMobileSidebarOpen(false);
      }
    };

    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [isMobileSidebarOpen]);

  function toggleSidebar() {
    if (isMobile) {
      setIsMobileSidebarOpen((prev) => !prev);
      return;
    }

    setIsSidebarCollapsed((prev) => {
      const next = !prev;
      window.localStorage.setItem(DESKTOP_SIDEBAR_KEY, next ? '1' : '0');
      return next;
    });
  }

  function closeMobileSidebar() {
    setIsMobileSidebarOpen(false);
  }

  const shellClassName = [
    styles.shell,
    isSidebarCollapsed && !isMobile ? styles.shellCollapsed : '',
    isMobile ? styles.shellMobile : '',
  ]
    .join(' ')
    .trim();

  return (
    <div className={styles.appFrame}>
      <div className={shellClassName}>
        <SidebarNav
          items={adminNavigation}
          activeItem={activeItem}
          isCollapsed={isSidebarCollapsed && !isMobile}
          isMobile={isMobile}
          isMobileOpen={isMobileSidebarOpen}
          onRequestClose={closeMobileSidebar}
          onToggleCollapse={toggleSidebar}
        />
        <AnimatePresence>
          {isMobile && isMobileSidebarOpen ? (
            <motion.button
              type="button"
              className={styles.sidebarBackdrop}
              aria-label="Close navigation menu"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.18 }}
              onClick={closeMobileSidebar}
            />
          ) : null}
        </AnimatePresence>
        <main className={styles.main}>
          <TopBar
            title={title}
            isMobile={isMobile}
            isSidebarCollapsed={isSidebarCollapsed && !isMobile}
            isMobileSidebarOpen={isMobileSidebarOpen}
            onMenuToggle={toggleSidebar}
          />
          <div className={styles.content}>{children}</div>
        </main>
      </div>
    </div>
  );
}
