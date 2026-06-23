'use client';

import dynamic from 'next/dynamic';
import { useCallback, useRef } from 'react';
import { useTranslations } from 'next-intl';
import { TopBarHeader } from './top-bar-header';
import { TopBarNotificationsPanel } from './top-bar-notifications-panel';
import { TopBarProfileMenu } from './top-bar-profile-menu';
import { useTopBarOverlays } from '../hooks/use-top-bar-overlays';
import { useTopBarNotifications } from '../hooks/use-top-bar-notifications';
import { useBellJiggleOnRealtime } from '../hooks/use-bell-jiggle-on-realtime';
import type { TopBarNotification } from '../types/top-bar';

const TopBarCommandPalette = dynamic(
  () => import('./top-bar-command-palette').then((m) => ({ default: m.TopBarCommandPalette })),
  { ssr: false },
);

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

  const preloadPalette = useCallback(() => {
    void import('./top-bar-command-palette');
  }, []);

  const { notifications, unreadNotificationsCount, markAllNotificationsRead, markNotificationRead } =
    useTopBarNotifications({ initialNotifications });

  const { isBellJingling } = useBellJiggleOnRealtime();

  const overlays = useTopBarOverlays({
    searchTriggerRef,
    notifyButtonRef,
    profileButtonRef,
    palettePanelRef,
    paletteInputRef,
    notificationsPanelRef,
    profileMenuRef,
    onPreloadPalette: preloadPalette,
  });

  return (
    <>
      <TopBarHeader
        title={title}
        isMobile={isMobile}
        isSidebarCollapsed={isSidebarCollapsed}
        isMobileSidebarOpen={isMobileSidebarOpen}
        searchPlaceholder={resolvedSearchPlaceholder}
        shortcutLabel={overlays.shortcutLabel}
        searchTriggerRef={searchTriggerRef}
        onMenuToggle={onMenuToggle}
        onOpenPalette={() => overlays.openPalette(searchTriggerRef.current)}
      >
        <TopBarNotificationsPanel
          isOpen={overlays.isNotificationsOpen}
          isBellJingling={isBellJingling}
          unreadNotificationsCount={unreadNotificationsCount}
          notifications={notifications}
          notifyButtonRef={notifyButtonRef}
          notificationsPanelRef={notificationsPanelRef}
          onToggle={overlays.toggleNotifications}
          onMarkAllRead={markAllNotificationsRead}
          onMarkRead={markNotificationRead}
          onClose={overlays.closeNotifications}
        />
        <TopBarProfileMenu
          isOpen={overlays.isProfileOpen}
          profileButtonRef={profileButtonRef}
          profileMenuRef={profileMenuRef}
          onToggle={overlays.toggleProfileMenu}
          onClose={overlays.closeProfile}
        />
      </TopBarHeader>

      {overlays.commandPalettePortalReady ? (
        <TopBarCommandPalette
          open={overlays.isPaletteOpen}
          portalReady={overlays.commandPalettePortalReady}
          shortcutLabel={overlays.shortcutLabel}
          query={overlays.query}
          activeIndex={overlays.activeIndex}
          flatResults={overlays.flatResults}
          groupedResults={overlays.groupedResults}
          activeItem={overlays.activeItem}
          entityLoading={overlays.entityLoading}
          entityErrors={overlays.entityErrors}
          resultCount={overlays.resultCount}
          palettePanelRef={palettePanelRef}
          paletteInputRef={paletteInputRef}
          onQueryChange={overlays.onQueryChange}
          onMoveSelection={overlays.moveSelection}
          onMoveToBoundary={overlays.moveToBoundary}
          onSelectIndex={overlays.selectIndex}
          onExecuteCommand={overlays.executeCommand}
          onClosePalette={overlays.closePalette}
        />
      ) : null}
    </>
  );
}
