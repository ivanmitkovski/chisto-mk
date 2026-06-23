'use client';

import { RefObject, useCallback, useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { signOutAndRedirectToLogin } from '@/features/auth/lib/admin-auth';
import { useCommandPalette } from './use-command-palette';
import { useOverlayDismiss } from './use-overlay-dismiss';
import type { ResolvedCommand } from '../commands/types';
import {
  isCommandPaletteShortcut,
  shouldBlockCommandPaletteShortcut,
} from '../lib/command-palette-shortcut-guard';
import { prefetchRouteMessages } from '@/i18n/prefetch-route-messages';

type UseTopBarOverlaysOptions = {
  searchTriggerRef: RefObject<HTMLInputElement | null>;
  notifyButtonRef: RefObject<HTMLButtonElement | null>;
  profileButtonRef: RefObject<HTMLButtonElement | null>;
  palettePanelRef: RefObject<HTMLDivElement | null>;
  paletteInputRef: RefObject<HTMLInputElement | null>;
  notificationsPanelRef: RefObject<HTMLDivElement | null>;
  profileMenuRef: RefObject<HTMLDivElement | null>;
  onPreloadPalette?: () => void;
};

export function useTopBarOverlays({
  searchTriggerRef,
  notifyButtonRef,
  profileButtonRef,
  palettePanelRef,
  paletteInputRef,
  notificationsPanelRef,
  profileMenuRef,
  onPreloadPalette,
}: UseTopBarOverlaysOptions) {
  const router = useRouter();
  const [isPaletteOpen, setIsPaletteOpen] = useState(false);
  const [isNotificationsOpen, setIsNotificationsOpen] = useState(false);
  const [isProfileOpen, setIsProfileOpen] = useState(false);
  const [shortcutLabel, setShortcutLabel] = useState('Ctrl+K');
  const [commandPalettePortalReady, setCommandPalettePortalReady] = useState(false);
  const paletteFocusReturnRef = useRef<HTMLElement | null>(null);

  const palette = useCommandPalette({ isOpen: isPaletteOpen });

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

  const executeCommand = useCallback(
    (command: ResolvedCommand) => {
      if (command.action.type === 'clear-recents') {
        palette.clearRecents();
        return;
      }

      if (command.action.type === 'navigate') {
        const { href } = command.action;
        palette.recordRecent(command.id);
        closePalette();
        void prefetchRouteMessages(href).finally(() => {
          router.push(href);
        });
        return;
      }

      if (command.action.type === 'open-profile') {
        palette.recordRecent(command.id);
        closePalette();
        setIsNotificationsOpen(false);
        setIsProfileOpen(true);
        profileButtonRef.current?.focus();
        return;
      }

      if (command.action.type === 'open-notifications-panel') {
        palette.recordRecent(command.id);
        closePalette();
        setIsProfileOpen(false);
        setIsNotificationsOpen(true);
        notifyButtonRef.current?.focus();
        return;
      }

      if (command.action.type === 'refresh-page') {
        palette.recordRecent(command.id);
        closePalette();
        router.refresh();
        return;
      }

      if (command.action.type === 'sign-out') {
        closePalette();
        void signOutAndRedirectToLogin();
      }
    },
    [closePalette, notifyButtonRef, palette, profileButtonRef, router],
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

  const closeNotifications = useCallback(() => setIsNotificationsOpen(false), []);
  const closeProfile = useCallback(() => setIsProfileOpen(false), []);

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
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() !== 'k') {
        onPreloadPalette?.();
      }

      const isShortcut = isCommandPaletteShortcut(event);
      if (!isShortcut) return;
      if (shouldBlockCommandPaletteShortcut(event.target)) return;

      event.preventDefault();
      togglePalette();
    };

    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [onPreloadPalette, togglePalette]);

  useEffect(() => {
    if (!isPaletteOpen) return;
    const timeoutId = window.setTimeout(() => paletteInputRef.current?.focus(), 0);
    return () => window.clearTimeout(timeoutId);
  }, [isPaletteOpen, paletteInputRef]);

  return {
    isPaletteOpen,
    isNotificationsOpen,
    isProfileOpen,
    shortcutLabel,
    commandPalettePortalReady,
    ...palette,
    openPalette,
    closePalette,
    toggleNotifications,
    toggleProfileMenu,
    closeNotifications,
    closeProfile,
    setIsNotificationsOpen,
    setIsProfileOpen,
    executeCommand,
  };
}
