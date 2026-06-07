'use client';

import { RefObject, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { signOutAndRedirectToLogin } from '@/features/auth/lib/admin-auth';
import { usePermissions } from '@/lib/auth/rbac/use-permissions';
import { topBarCommands } from '../data/top-bar-mocks';
import { resolveTopBarCommand } from '../lib/resolve-top-bar-command';
import { useCommandPalette } from './use-command-palette';
import { useOverlayDismiss } from './use-overlay-dismiss';
import type { TopBarCommand } from '../types/top-bar';

type UseTopBarOverlaysOptions = {
  searchTriggerRef: RefObject<HTMLInputElement | null>;
  notifyButtonRef: RefObject<HTMLButtonElement | null>;
  profileButtonRef: RefObject<HTMLButtonElement | null>;
  palettePanelRef: RefObject<HTMLDivElement | null>;
  paletteInputRef: RefObject<HTMLInputElement | null>;
  notificationsPanelRef: RefObject<HTMLDivElement | null>;
  profileMenuRef: RefObject<HTMLDivElement | null>;
};

export function useTopBarOverlays({
  searchTriggerRef,
  notifyButtonRef,
  profileButtonRef,
  palettePanelRef,
  paletteInputRef,
  notificationsPanelRef,
  profileMenuRef,
}: UseTopBarOverlaysOptions) {
  const router = useRouter();
  const { can } = usePermissions();
  const tNav = useTranslations('nav');
  const tCommon = useTranslations('common');
  const paletteFocusReturnRef = useRef<HTMLElement | null>(null);

  const permittedCommands = useMemo(() => {
    const allowed = topBarCommands.filter((command) => !command.permission || can(command.permission));
    return allowed.map((command) => resolveTopBarCommand(command, tNav, tCommon));
  }, [can, tCommon, tNav]);

  const [isPaletteOpen, setIsPaletteOpen] = useState(false);
  const [isNotificationsOpen, setIsNotificationsOpen] = useState(false);
  const [isProfileOpen, setIsProfileOpen] = useState(false);
  const [shortcutLabel, setShortcutLabel] = useState('Ctrl+K');
  const [commandPalettePortalReady, setCommandPalettePortalReady] = useState(false);

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
    commands: permittedCommands,
  });

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
  }, [closePalette, isPaletteOpen, openPalette, searchTriggerRef]);

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
        void signOutAndRedirectToLogin();
        return;
      }
    },
    [closePalette, profileButtonRef, router],
  );

  const toggleNotifications = useCallback(() => {
    setIsNotificationsOpen((prev) => {
      const next = !prev;
      if (next) {
        setIsProfileOpen(false);
        setIsPaletteOpen(false);
      }
      return next;
    });
  }, []);

  const toggleProfileMenu = useCallback(() => {
    setIsProfileOpen((prev) => {
      const next = !prev;
      if (next) {
        setIsNotificationsOpen(false);
        setIsPaletteOpen(false);
      }
      return next;
    });
  }, []);

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
    setCommandPalettePortalReady(true);
  }, []);

  useEffect(() => {
    const platformLabel = window.navigator.platform.toLowerCase().includes('mac') ? '⌘K' : 'Ctrl+K';
    setShortcutLabel(platformLabel);
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
  }, [isPaletteOpen, paletteInputRef]);

  return {
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
    closePalette,
    toggleNotifications,
    toggleProfileMenu,
    closeNotifications,
    closeProfile,
    setIsNotificationsOpen,
    setIsProfileOpen,
    executeCommand,
    moveSelection,
    moveToBoundary,
  };
}
