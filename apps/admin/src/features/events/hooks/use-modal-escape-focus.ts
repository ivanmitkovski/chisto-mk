'use client';

import { useEffect, type RefObject } from 'react';

export function useModalEscapeFocus(
  open: boolean,
  options: {
    onEscape: () => void;
    focusRef: RefObject<HTMLElement | null>;
  },
): void {
  const { onEscape, focusRef } = options;

  useEffect(() => {
    if (!open) {
      return;
    }
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        onEscape();
      }
    };
    document.addEventListener('keydown', onKeyDown);
    const id = requestAnimationFrame(() => {
      focusRef.current?.focus();
    });
    return () => {
      document.removeEventListener('keydown', onKeyDown);
      cancelAnimationFrame(id);
    };
  }, [open, onEscape, focusRef]);
}
