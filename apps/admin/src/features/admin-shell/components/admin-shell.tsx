'use client';

import { ReactNode, useEffect, useState } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { adminNavigation } from '../config/navigation';
import { DESKTOP_SIDEBAR_COOKIE_KEY, DESKTOP_SIDEBAR_STORAGE_KEY } from '../constants';
import { NavItemKey } from '../types';
import { SidebarNav } from './sidebar-nav';
import { TopBar } from './top-bar';
import styles from './admin-shell.module.css';

type AdminShellProps = {
  title: string;
  activeItem: NavItemKey;
  children: ReactNode;
  initialSidebarCollapsed?: boolean;
};

const SIDEBAR_PREFERENCE_COOKIE_MAX_AGE_SECONDS = 60 * 60 * 24 * 365;

function persistSidebarPreference(nextIsCollapsed: boolean) {
  const serializedValue = nextIsCollapsed ? '1' : '0';
  window.localStorage.setItem(DESKTOP_SIDEBAR_STORAGE_KEY, serializedValue);
  document.cookie = `${DESKTOP_SIDEBAR_COOKIE_KEY}=${serializedValue}; path=/; max-age=${SIDEBAR_PREFERENCE_COOKIE_MAX_AGE_SECONDS}; samesite=lax`;
}

export function AdminShell({ title, activeItem, children, initialSidebarCollapsed = false }: AdminShellProps) {
  const [isMobile, setIsMobile] = useState(false);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(initialSidebarCollapsed);
  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState(false);
  const [isSidebarPreferenceHydrated, setIsSidebarPreferenceHydrated] = useState(false);

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
    const persistedValue = window.localStorage.getItem(DESKTOP_SIDEBAR_STORAGE_KEY);

    if (persistedValue === '1' || persistedValue === '0') {
      const persistedIsCollapsed = persistedValue === '1';
      if (persistedIsCollapsed !== initialSidebarCollapsed) {
        setIsSidebarCollapsed(persistedIsCollapsed);
      }
      persistSidebarPreference(persistedIsCollapsed);
    } else {
      persistSidebarPreference(initialSidebarCollapsed);
    }

    const animationFrameId = window.requestAnimationFrame(() => {
      setIsSidebarPreferenceHydrated(true);
    });

    return () => window.cancelAnimationFrame(animationFrameId);
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
      persistSidebarPreference(next);
      return next;
    });
  }

  function closeMobileSidebar() {
    setIsMobileSidebarOpen(false);
  }

  const shellClassName = [
    styles.shell,
    !isSidebarPreferenceHydrated ? styles.shellNoTransition : '',
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
