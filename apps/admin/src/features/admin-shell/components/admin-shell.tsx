'use client';

import { ReactNode, useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { AnimatePresence, motion } from 'framer-motion';
import { Modal } from '@/components/ui';
import { adminNavigation } from '../config/navigation';
import { NAV_PERMISSIONS } from '@/lib/auth/rbac';
import { usePermissions } from '@/lib/auth/rbac';
import { DESKTOP_SIDEBAR_COOKIE_KEY, DESKTOP_SIDEBAR_STORAGE_KEY } from '../constants';
import { NavItemKey } from '../types';
import { SidebarNav } from './sidebar-nav';
import { TopBar } from './top-bar';
import { useAdminSessionKeepalive } from '@/features/auth/hooks/use-admin-session-keepalive';
import styles from './admin-shell.module.css';

type AdminShellProps = {
  title: string;
  activeItem: NavItemKey;
  children: ReactNode;
  initialSidebarCollapsed?: boolean;
  initialTopBarNotifications?: import('../types/top-bar').TopBarNotification[];
  contentMode?: 'default' | 'immersive';
};

const SIDEBAR_PREFERENCE_COOKIE_MAX_AGE_SECONDS = 60 * 60 * 24 * 365;

function persistSidebarPreference(nextIsCollapsed: boolean) {
  const serializedValue = nextIsCollapsed ? '1' : '0';
  window.localStorage.setItem(DESKTOP_SIDEBAR_STORAGE_KEY, serializedValue);
  document.cookie = `${DESKTOP_SIDEBAR_COOKIE_KEY}=${serializedValue}; path=/; max-age=${SIDEBAR_PREFERENCE_COOKIE_MAX_AGE_SECONDS}; samesite=lax`;
}

export function AdminShell({
  title,
  activeItem,
  children,
  initialSidebarCollapsed = false,
  initialTopBarNotifications,
  contentMode = 'default',
}: AdminShellProps) {
  const tCommon = useTranslations('common');
  const { can } = usePermissions();
  const visibleNavigation = adminNavigation.filter((item) => {
    const permission = NAV_PERMISSIONS[item.key];
    return permission ? can(permission) : true;
  });
  const [isMobile, setIsMobile] = useState(false);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(initialSidebarCollapsed);
  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState(false);
  const [isSidebarPreferenceHydrated, setIsSidebarPreferenceHydrated] = useState(false);
  const [showShortcuts, setShowShortcuts] = useState(false);

  useAdminSessionKeepalive();

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
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === '?' && !event.metaKey && !event.ctrlKey && !event.altKey) {
        const target = event.target as HTMLElement | null;
        if (target?.closest('input, textarea, select, [contenteditable="true"]')) {
          return;
        }
        event.preventDefault();
        setShowShortcuts(true);
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, []);

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
      <a href="#admin-main" className="skipLink">
        {tCommon('skipToMain')}
      </a>
      <div className={shellClassName}>
        <SidebarNav
          items={visibleNavigation}
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
              aria-label={tCommon('closeNavigationMenu')}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.18 }}
              onClick={closeMobileSidebar}
            />
          ) : null}
        </AnimatePresence>
        <main id="admin-main" className={styles.main} tabIndex={-1}>
          <TopBar
            title={title}
            isMobile={isMobile}
            isSidebarCollapsed={isSidebarCollapsed && !isMobile}
            isMobileSidebarOpen={isMobileSidebarOpen}
            onMenuToggle={toggleSidebar}
            initialNotifications={initialTopBarNotifications ?? []}
          />
          <div className={`${styles.content} ${contentMode === 'immersive' ? styles.contentImmersive : ''}`}>
            <div className={styles.contentFrame}>{children}</div>
          </div>
        </main>
      </div>
      <Modal open={showShortcuts} title={tCommon('keyboardShortcuts')} onClose={() => setShowShortcuts(false)}>
        <dl className={styles.shortcuts}>
          <div>
            <dt>?</dt>
            <dd>{tCommon('shortcutShowPanel')}</dd>
          </div>
          <div>
            <dt>Esc</dt>
            <dd>{tCommon('shortcutCloseOverlays')}</dd>
          </div>
          <div>
            <dt>Tab</dt>
            <dd>{tCommon('shortcutFocusTrap')}</dd>
          </div>
        </dl>
      </Modal>
    </div>
  );
}
