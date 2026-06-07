'use client';

import { useRef } from 'react';
import { useTranslations } from 'next-intl';
import { TopBarHeader } from './top-bar-header';
import { TopBarCommandPalette } from './top-bar-command-palette';
import { TopBarNotificationsPanel } from './top-bar-notifications-panel';
import { TopBarProfileMenu } from './top-bar-profile-menu';
import { useTopBarOverlays } from '../hooks/use-top-bar-overlays';
import { useTopBarNotifications } from '../hooks/use-top-bar-notifications';
import { useBellJiggleOnRealtime } from '../hooks/use-bell-jiggle-on-realtime';
import type { TopBarNotification } from '../types/top-bar';

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
  searchPlaceholder,
}: TopBarProps) {
  const t = useTranslations('common');
  const resolvedSearchPlaceholder = searchPlaceholder ?? t('commandMenu');
  const searchTriggerRef = useRef<HTMLInputElement>(null);
  const notifyButtonRef = useRef<HTMLButtonElement>(null);
  const profileButtonRef = useRef<HTMLButtonElement>(null);
  const palettePanelRef = useRef<HTMLDivElement>(null);
  const paletteInputRef = useRef<HTMLInputElement>(null);
  const notificationsPanelRef = useRef<HTMLDivElement>(null);
  const profileMenuRef = useRef<HTMLDivElement>(null);

  const { notifications, unreadNotificationsCount, markAllNotificationsRead, markNotificationRead } =
    useTopBarNotifications({ initialNotifications });

  const { isBellJingling } = useBellJiggleOnRealtime();

  const {
    isPaletteOpen,
    isNotificationsOpen,
    isProfileOpen,
    shortcutLabel,
    commandPalettePortalReady,
    query,
    activeIndex,
    filteredCommands,
    activeCommand,
    onQueryChange,
    selectIndex,
    openPalette,
    toggleNotifications,
    toggleProfileMenu,
    closeNotifications,
    closeProfile,
    executeCommand,
    moveSelection,
    moveToBoundary,
    closePalette,
  } = useTopBarOverlays({
    searchTriggerRef,
    notifyButtonRef,
    profileButtonRef,
    palettePanelRef,
    paletteInputRef,
    notificationsPanelRef,
    profileMenuRef,
  });

  return (
    <>
      <TopBarHeader
        title={title}
        isMobile={isMobile}
        isSidebarCollapsed={isSidebarCollapsed}
        isMobileSidebarOpen={isMobileSidebarOpen}
        searchPlaceholder={resolvedSearchPlaceholder}
        shortcutLabel={shortcutLabel}
        searchTriggerRef={searchTriggerRef}
        onMenuToggle={onMenuToggle}
        onOpenPalette={() => openPalette(searchTriggerRef.current)}
      >
        <TopBarNotificationsPanel
          isOpen={isNotificationsOpen}
          isBellJingling={isBellJingling}
          unreadNotificationsCount={unreadNotificationsCount}
          notifications={notifications}
          notifyButtonRef={notifyButtonRef}
          notificationsPanelRef={notificationsPanelRef}
          onToggle={toggleNotifications}
          onMarkAllRead={markAllNotificationsRead}
          onMarkRead={markNotificationRead}
          onClose={closeNotifications}
        />
        <TopBarProfileMenu
          isOpen={isProfileOpen}
          profileButtonRef={profileButtonRef}
          profileMenuRef={profileMenuRef}
          onToggle={toggleProfileMenu}
          onClose={closeProfile}
        />
      </TopBarHeader>

      <TopBarCommandPalette
        isOpen={isPaletteOpen}
        portalReady={commandPalettePortalReady}
        query={query}
        activeIndex={activeIndex}
        filteredCommands={filteredCommands}
        activeCommand={activeCommand}
        palettePanelRef={palettePanelRef}
        paletteInputRef={paletteInputRef}
        onQueryChange={onQueryChange}
        onMoveSelection={moveSelection}
        onMoveToBoundary={moveToBoundary}
        onSelectIndex={selectIndex}
        onExecuteCommand={executeCommand}
        onClosePalette={closePalette}
      />
    </>
  );
}
