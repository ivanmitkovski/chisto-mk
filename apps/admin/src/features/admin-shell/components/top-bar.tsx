'use client';

import { KeyboardEvent as ReactKeyboardEvent, useCallback, useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import { Button } from '@/components/ui/button/button';
import { Icon } from '@/components/ui/icon/icon';
import { Input } from '@/components/ui/input/input';
import { useNotifications } from '@/features/notifications/context/notifications-context';
import { subscribeNewReportSignal } from '@/lib/realtime-signals';
import { profileMenuActions, topBarCommands } from '../data/top-bar-mocks';
import { useCommandPalette } from '../hooks/use-command-palette';
import { useOverlayDismiss } from '../hooks/use-overlay-dismiss';
import { TopBarCommand, TopBarNotification } from '../types/top-bar';
import { logoutAdmin } from '@/features/auth/lib/admin-auth';
import styles from './top-bar.module.css';

const DEBUG_REALTIME_FLAG = 'chisto:debug-realtime';

type TopBarProps = {
  title: string;
  isMobile: boolean;
  isSidebarCollapsed: boolean;
  isMobileSidebarOpen: boolean;
  onMenuToggle: () => void;
  initialNotifications?: TopBarNotification[];
  searchPlaceholder?: string;
};

export function TopBar({
  title,
  isMobile,
  isSidebarCollapsed,
  isMobileSidebarOpen,
  onMenuToggle,
  initialNotifications = [],
  searchPlaceholder = 'Search reports',
}: TopBarProps) {
  const router = useRouter();
  const reduceMotion = useReducedMotion();
  const searchTriggerRef = useRef<HTMLInputElement>(null);
  const notifyButtonRef = useRef<HTMLButtonElement>(null);
  const profileButtonRef = useRef<HTMLButtonElement>(null);
  const palettePanelRef = useRef<HTMLDivElement>(null);
  const paletteInputRef = useRef<HTMLInputElement>(null);
  const notificationsPanelRef = useRef<HTMLDivElement>(null);
  const profileMenuRef = useRef<HTMLDivElement>(null);
  const paletteFocusReturnRef = useRef<HTMLElement | null>(null);

  const notificationsContext = useNotifications();
  const [isPaletteOpen, setIsPaletteOpen] = useState(false);
  const [isNotificationsOpen, setIsNotificationsOpen] = useState(false);
  const [isProfileOpen, setIsProfileOpen] = useState(false);
  const [isBellJingling, setIsBellJingling] = useState(false);
  const [shortcutLabel, setShortcutLabel] = useState('Ctrl+K');
  const [localNotifications, setLocalNotifications] = useState<TopBarNotification[]>(() =>
    initialNotifications.map((n) => ({ ...n })),
  );

  const notifications = notificationsContext?.items ?? localNotifications;
  const unreadNotificationsCount =
    notificationsContext?.unreadCount ?? notifications.filter((n) => n.isUnread).length;
  const bellJiggleTimeoutRef = useRef<number | null>(null);
  const lastBellJiggleRef = useRef(0);

  const isRealtimeDebugEnabled = useCallback(() => {
    if (typeof window === 'undefined') return false;
    return process.env.NODE_ENV !== 'production' && window.localStorage.getItem(DEBUG_REALTIME_FLAG) === '1';
  }, []);

  const {
    query,
    activeIndex,
    filteredCommands,
    activeCommand,
    onQueryChange,
    moveSelection,
    moveToBoundary,
    selectIndex,
  } = useCommandPalette({
    isOpen: isPaletteOpen,
    commands: topBarCommands,
  });

  const menuIcon = isMobile ? (isMobileSidebarOpen ? 'x' : 'menu') : isSidebarCollapsed ? 'panel-left-open' : 'panel-left-close';
  const menuLabel = isMobile
    ? isMobileSidebarOpen
      ? 'Close menu'
      : 'Open menu'
    : isSidebarCollapsed
      ? 'Expand sidebar'
      : 'Collapse sidebar';

  const closePalette = useCallback(() => {
    setIsPaletteOpen(false);
    window.setTimeout(() => {
      paletteFocusReturnRef.current?.focus();
      paletteFocusReturnRef.current = null;
    }, 0);
  }, []);

  const openPalette = useCallback((focusReturnTarget?: HTMLElement | null) => {
    paletteFocusReturnRef.current =
      focusReturnTarget ?? (document.activeElement instanceof HTMLElement ? document.activeElement : null);
    setIsPaletteOpen(true);
    setIsNotificationsOpen(false);
    setIsProfileOpen(false);
  }, []);

  const togglePalette = useCallback(() => {
    if (isPaletteOpen) {
      closePalette();
      return;
    }

    openPalette(searchTriggerRef.current);
  }, [closePalette, isPaletteOpen, openPalette]);

  const closeNotifications = useCallback(() => {
    setIsNotificationsOpen(false);
  }, []);

  const closeProfile = useCallback(() => {
    setIsProfileOpen(false);
  }, []);

  const executeCommand = useCallback(
    (command: TopBarCommand) => {
      if (command.action.type === 'navigate') {
        closePalette();
        router.push(command.action.href);
        return;
      }

      if (command.action.type === 'open-profile') {
        closePalette();
        setIsNotificationsOpen(false);
        setIsProfileOpen(true);
        profileButtonRef.current?.focus();
        return;
      }

      if (command.action.type === 'sign-out') {
        closePalette();
        logoutAdmin();
        router.push('/login');
        return;
      }
    },
    [closePalette, router],
  );

  function onPaletteInputKeyDown(event: ReactKeyboardEvent<HTMLInputElement>) {
    if (event.key === 'ArrowDown') {
      event.preventDefault();
      moveSelection(1);
      return;
    }

    if (event.key === 'ArrowUp') {
      event.preventDefault();
      moveSelection(-1);
      return;
    }

    if (event.key === 'Home') {
      event.preventDefault();
      moveToBoundary('start');
      return;
    }

    if (event.key === 'End') {
      event.preventDefault();
      moveToBoundary('end');
      return;
    }

    if (event.key === 'Enter' && activeCommand) {
      event.preventDefault();
      executeCommand(activeCommand);
      return;
    }

    if (event.key === 'Escape') {
      event.preventDefault();
      closePalette();
    }
  }

  function onPaletteTrapKeyDown(event: ReactKeyboardEvent<HTMLDivElement>) {
    if (event.key !== 'Tab') {
      return;
    }

    const focusableElements = palettePanelRef.current?.querySelectorAll<HTMLElement>(
      'button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])',
    );

    if (!focusableElements || focusableElements.length === 0) {
      return;
    }

    const firstElement = focusableElements[0];
    const lastElement = focusableElements[focusableElements.length - 1];
    const activeElement = document.activeElement;

    if (!event.shiftKey && activeElement === lastElement) {
      event.preventDefault();
      firstElement.focus();
      return;
    }

    if (event.shiftKey && activeElement === firstElement) {
      event.preventDefault();
      lastElement.focus();
    }
  }

  function toggleNotifications() {
    setIsNotificationsOpen((prev) => {
      const next = !prev;
      if (next) {
        setIsProfileOpen(false);
        setIsPaletteOpen(false);
      }
      return next;
    });
  }

  function toggleProfileMenu() {
    setIsProfileOpen((prev) => {
      const next = !prev;
      if (next) {
        setIsNotificationsOpen(false);
        setIsPaletteOpen(false);
      }
      return next;
    });
  }

  function markAllNotificationsRead() {
    if (notificationsContext) {
      void notificationsContext.markAllRead();
    } else {
      setLocalNotifications((prev) =>
        prev.map((n) => (n.isUnread ? { ...n, isUnread: false } : n)),
      );
    }
  }

  function markNotificationRead(id: string) {
    if (notificationsContext) {
      void notificationsContext.markOneRead(id);
    } else {
      setLocalNotifications((prev) =>
        prev.map((n) =>
          n.id === id && n.isUnread ? { ...n, isUnread: false } : n,
        ),
      );
    }
  }

  function handleProfileAction(action: (typeof profileMenuActions)[number]['action']) {
    if (action === 'go-to-settings') {
      setIsProfileOpen(false);
      router.push('/dashboard/settings');
      return;
    }

    if (action === 'open-preferences') {
      setIsProfileOpen(false);
      router.push('/dashboard/settings?section=preferences');
      return;
    }

    if (action === 'sign-out') {
      setIsProfileOpen(false);
      logoutAdmin();
      router.push('/login');
      return;
    }
  }

  useOverlayDismiss({
    isOpen: isPaletteOpen,
    containerRef: palettePanelRef,
    triggerRef: searchTriggerRef,
    onDismiss: closePalette,
  });

  useOverlayDismiss({
    isOpen: isNotificationsOpen,
    containerRef: notificationsPanelRef,
    triggerRef: notifyButtonRef,
    onDismiss: closeNotifications,
  });

  useOverlayDismiss({
    isOpen: isProfileOpen,
    containerRef: profileMenuRef,
    triggerRef: profileButtonRef,
    onDismiss: closeProfile,
  });

  useEffect(() => {
    const platformLabel = window.navigator.platform.toLowerCase().includes('mac') ? '⌘K' : 'Ctrl+K';
    setShortcutLabel(platformLabel);
  }, []);

  useEffect(() => {
    return subscribeNewReportSignal((payload) => {
      if (reduceMotion) return;
      const now = Date.now();
      if (now - lastBellJiggleRef.current < 3000) return;
      lastBellJiggleRef.current = now;
      setIsBellJingling(true);
      if (isRealtimeDebugEnabled()) {
        console.debug('[realtime] bell-jiggle', { reportId: payload.reportId, atMs: now });
      }
      if (bellJiggleTimeoutRef.current != null) {
        window.clearTimeout(bellJiggleTimeoutRef.current);
      }
      bellJiggleTimeoutRef.current = window.setTimeout(() => {
        setIsBellJingling(false);
        bellJiggleTimeoutRef.current = null;
      }, 650);
    });
  }, [isRealtimeDebugEnabled, reduceMotion]);

  useEffect(() => {
    return () => {
      if (bellJiggleTimeoutRef.current != null) {
        window.clearTimeout(bellJiggleTimeoutRef.current);
      }
    };
  }, []);

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      const isShortcut = (event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k';

      if (!isShortcut) {
        return;
      }

      event.preventDefault();
      togglePalette();
    };

    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [togglePalette]);

  useEffect(() => {
    if (!isPaletteOpen) {
      return;
    }

    const timeoutId = window.setTimeout(() => {
      paletteInputRef.current?.focus();
    }, 0);

    return () => window.clearTimeout(timeoutId);
  }, [isPaletteOpen]);

  return (
    <>
      <motion.header
        className={styles.topbar}
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
            aria-label="Open command palette"
            placeholder={searchPlaceholder}
            className={styles.searchInput}
            readOnly
            value=""
            leftSlot={<Icon name="magnifying-glass" size={14} />}
            rightSlot={<span className={styles.shortcutPill}>{shortcutLabel}</span>}
            onClick={() => openPalette(searchTriggerRef.current)}
            onKeyDown={(event) => {
              if (event.key === 'Enter' || event.key === ' ') {
                event.preventDefault();
                openPalette(searchTriggerRef.current);
              }
            }}
          />
          <motion.div
            className={styles.iconCluster}
            initial={reduceMotion ? false : { opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: reduceMotion ? 0 : 0.05, duration: reduceMotion ? 0 : 0.2, ease: 'easeOut' }}
          >
            <motion.span
              className={styles.notifyWrap}
              {...(!reduceMotion ? { whileHover: { y: -1 } } : {})}
            >
              <Button
                ref={notifyButtonRef}
                variant="icon"
                aria-label={
                  unreadNotificationsCount > 0
                    ? `Notifications, ${unreadNotificationsCount} unread`
                    : 'Notifications'
                }
                aria-expanded={isNotificationsOpen}
                aria-haspopup="dialog"
                className={`${styles.iconButton} ${isNotificationsOpen ? styles.iconButtonOpen : ''} ${isBellJingling ? styles.iconButtonJiggle : ''}`}
                onClick={toggleNotifications}
              >
                <Icon name="notification-bing" size={16} />
              </Button>
              {unreadNotificationsCount > 0 ? <span className={styles.notifyDot} aria-hidden /> : null}

              <AnimatePresence>
                {isNotificationsOpen ? (
                  <motion.section
                    ref={notificationsPanelRef}
                    className={styles.dropdownPanel}
                    role="dialog"
                    aria-label="Notifications panel"
                    initial={reduceMotion ? false : { opacity: 0, y: -6, scale: 0.98 }}
                    animate={{ opacity: 1, y: 0, scale: 1 }}
                    exit={reduceMotion ? { opacity: 0 } : { opacity: 0, y: -6, scale: 0.98 }}
                    transition={{ duration: reduceMotion ? 0 : 0.16 }}
                  >
                    <header className={styles.panelHeader}>
                      <div>
                        <h2 className={styles.panelTitle}>Notifications</h2>
                        <p className={styles.panelSubtitle}>{unreadNotificationsCount} unread</p>
                      </div>
                      <button
                        type="button"
                        className={styles.panelAction}
                        disabled={unreadNotificationsCount === 0}
                        onClick={markAllNotificationsRead}
                      >
                        Mark all read
                      </button>
                    </header>
                    <div
                      className={styles.notificationListScroll}
                      role="region"
                      aria-label="Notification list"
                    >
                      <ul className={styles.notificationList}>
                        {notifications.map((notification) => (
                          <li key={notification.id}>
                            <button
                              type="button"
                              className={`${styles.notificationItem} ${notification.isUnread ? styles.notificationUnread : ''}`}
                              onClick={() => {
                                void markNotificationRead(notification.id);
                                if (notification.href) {
                                  setIsNotificationsOpen(false);
                                  router.push(notification.href);
                                }
                              }}
                            >
                              <span className={styles.notificationHeading}>
                                {notification.title}
                                {notification.isUnread ? <span className={styles.unreadPill}>New</span> : null}
                              </span>
                              <span className={styles.notificationMessage}>{notification.message}</span>
                              <span className={styles.notificationTime}>{notification.timeLabel}</span>
                            </button>
                          </li>
                        ))}
                      </ul>
                    </div>
                    <div className={styles.notificationFooter}>
                      <button
                        type="button"
                        className={styles.notificationLink}
                        onClick={() => {
                          setIsNotificationsOpen(false);
                          router.push('/dashboard/notifications');
                        }}
                      >
                        View all notifications
                      </button>
                    </div>
                  </motion.section>
                ) : null}
              </AnimatePresence>
            </motion.span>
            <motion.span
              className={styles.profileWrap}
              {...(!reduceMotion ? { whileHover: { y: -1 } } : {})}
            >
              <Button
                ref={profileButtonRef}
                variant="icon"
                aria-label="Profile"
                aria-expanded={isProfileOpen}
                aria-haspopup="menu"
                className={`${styles.profileButton} ${isProfileOpen ? styles.iconButtonOpen : ''}`}
                onClick={toggleProfileMenu}
              >
                <Icon name="user" size={16} />
              </Button>
              <AnimatePresence>
                {isProfileOpen ? (
                  <motion.section
                    ref={profileMenuRef}
                    className={`${styles.dropdownPanel} ${styles.profileMenu}`}
                    role="menu"
                    aria-label="Profile actions"
                    initial={reduceMotion ? false : { opacity: 0, y: -6, scale: 0.98 }}
                    animate={{ opacity: 1, y: 0, scale: 1 }}
                    exit={reduceMotion ? { opacity: 0 } : { opacity: 0, y: -6, scale: 0.98 }}
                    transition={{ duration: reduceMotion ? 0 : 0.16 }}
                  >
                    <ul className={styles.profileActions}>
                      {profileMenuActions.map((item) => (
                        <li key={item.id}>
                          <button
                            type="button"
                            role="menuitem"
                            className={styles.profileActionButton}
                            onClick={() => handleProfileAction(item.action)}
                          >
                            <Icon name={item.icon} size={15} />
                            {item.label}
                          </button>
                        </li>
                      ))}
                    </ul>
                  </motion.section>
                ) : null}
              </AnimatePresence>
            </motion.span>
          </motion.div>
        </div>
      </motion.header>

      <AnimatePresence>
        {isPaletteOpen ? (
          <motion.div
            className={styles.paletteBackdrop}
            initial={reduceMotion ? false : { opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: reduceMotion ? 0 : 0.16 }}
          >
            <motion.section
              ref={palettePanelRef}
              className={styles.palette}
              role="dialog"
              aria-modal="true"
              aria-label="Command palette"
              initial={reduceMotion ? false : { opacity: 0, y: 10, scale: 0.98 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={reduceMotion ? { opacity: 0 } : { opacity: 0, y: 6, scale: 0.98 }}
              transition={{ duration: reduceMotion ? 0 : 0.18, ease: 'easeOut' }}
              onKeyDown={onPaletteTrapKeyDown}
            >
              <div className={styles.paletteSearchWrap}>
                <Input
                  inputRef={paletteInputRef}
                  aria-label="Search commands"
                  role="combobox"
                  aria-expanded
                  aria-controls="command-palette-list"
                  aria-autocomplete="list"
                  aria-activedescendant={activeCommand ? `command-option-${activeCommand.id}` : undefined}
                  placeholder="Type a command or route"
                  value={query}
                  onChange={onQueryChange}
                  onKeyDown={onPaletteInputKeyDown}
                  className={styles.paletteSearch}
                  leftSlot={<Icon name="magnifying-glass" size={14} />}
                />
              </div>
              <ul id="command-palette-list" role="listbox" className={styles.commandList} aria-label="Available commands">
                {filteredCommands.map((command, index) => (
                  <li key={command.id}>
                    <button
                      type="button"
                      role="option"
                      id={`command-option-${command.id}`}
                      aria-selected={index === activeIndex}
                      className={`${styles.commandItem} ${index === activeIndex ? styles.commandItemActive : ''}`}
                      onMouseEnter={() => selectIndex(index)}
                      onClick={() => executeCommand(command)}
                    >
                      <span className={styles.commandIcon}>
                        <Icon name={command.icon} size={14} />
                      </span>
                      <span className={styles.commandText}>
                        <strong>{command.label}</strong>
                        {command.description ? <small>{command.description}</small> : null}
                      </span>
                    </button>
                  </li>
                ))}
                {filteredCommands.length === 0 ? (
                  <li className={styles.emptyResults} role="status">
                    No commands match your query.
                  </li>
                ) : null}
              </ul>
            </motion.section>
          </motion.div>
        ) : null}
      </AnimatePresence>
    </>
  );
}
