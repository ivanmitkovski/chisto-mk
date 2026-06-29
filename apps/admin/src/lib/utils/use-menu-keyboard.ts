'use client';

import { useCallback, useEffect, useRef, type RefObject } from 'react';

const MENU_ITEM_SELECTOR =
  '[role="menuitem"], [role="menuitemcheckbox"], [role="menuitemradio"], a[role="menuitem"]';

function getMenuItems(container: HTMLElement): HTMLElement[] {
  return Array.from(container.querySelectorAll<HTMLElement>(MENU_ITEM_SELECTOR)).filter(
    (el) => !el.hasAttribute('disabled') && el.getAttribute('aria-disabled') !== 'true',
  );
}

export type UseMenuKeyboardOptions = {
  isOpen: boolean;
  menuRef: RefObject<HTMLElement | null>;
  onClose: () => void;
  orientation?: 'vertical' | 'horizontal';
};

/**
 * WAI-ARIA menu keyboard pattern: arrows, Home/End, typeahead, Escape (caller), Tab closes.
 */
export function useMenuKeyboard({
  isOpen,
  menuRef,
  onClose,
  orientation = 'vertical',
}: UseMenuKeyboardOptions): void {
  const typeaheadRef = useRef('');
  const typeaheadTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const focusItem = useCallback(
    (index: number) => {
      const menu = menuRef.current;
      if (!menu) return;
      const items = getMenuItems(menu);
      if (items.length === 0) return;
      const next = items[Math.max(0, Math.min(index, items.length - 1))];
      next?.focus({ preventScroll: false });
      next?.scrollIntoView({ block: 'nearest', inline: 'nearest' });
    },
    [menuRef],
  );

  const handleKeyDown = useCallback(
    (event: KeyboardEvent) => {
      const menu = menuRef.current;
      if (!menu || !isOpen) return;

      const items = getMenuItems(menu);
      if (items.length === 0) return;

      const activeIndex = items.findIndex((item) => item === document.activeElement);
      const prevKey = orientation === 'vertical' ? 'ArrowUp' : 'ArrowLeft';
      const nextKey = orientation === 'vertical' ? 'ArrowDown' : 'ArrowRight';

      if (event.key === nextKey) {
        event.preventDefault();
        focusItem(activeIndex < 0 ? 0 : (activeIndex + 1) % items.length);
        return;
      }

      if (event.key === prevKey) {
        event.preventDefault();
        focusItem(activeIndex < 0 ? items.length - 1 : (activeIndex - 1 + items.length) % items.length);
        return;
      }

      if (event.key === 'Home') {
        event.preventDefault();
        focusItem(0);
        return;
      }

      if (event.key === 'End') {
        event.preventDefault();
        focusItem(items.length - 1);
        return;
      }

      if (event.key === 'Tab') {
        onClose();
        return;
      }

      if (event.key.length === 1 && !event.ctrlKey && !event.metaKey && !event.altKey) {
        const char = event.key.toLowerCase();
        typeaheadRef.current += char;
        if (typeaheadTimerRef.current) clearTimeout(typeaheadTimerRef.current);
        typeaheadTimerRef.current = setTimeout(() => {
          typeaheadRef.current = '';
        }, 500);

        const query = typeaheadRef.current;
        const start = activeIndex < 0 ? 0 : activeIndex + 1;
        for (let offset = 0; offset < items.length; offset += 1) {
          const idx = (start + offset) % items.length;
          const text = items[idx]?.textContent?.trim().toLowerCase() ?? '';
          if (text.startsWith(query)) {
            event.preventDefault();
            focusItem(idx);
            return;
          }
        }
      }
    },
    [focusItem, isOpen, menuRef, onClose, orientation],
  );

  useEffect(() => {
    if (!isOpen) {
      typeaheadRef.current = '';
      if (typeaheadTimerRef.current) clearTimeout(typeaheadTimerRef.current);
      return;
    }

    const menu = menuRef.current;
    if (!menu) return;

    const items = getMenuItems(menu);
    if (items.length > 0 && !menu.contains(document.activeElement)) {
      items[0]?.focus();
    }

    window.addEventListener('keydown', handleKeyDown);
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      if (typeaheadTimerRef.current) clearTimeout(typeaheadTimerRef.current);
    };
  }, [handleKeyDown, isOpen, menuRef]);
}
