'use client';

import { useEffect, useState, type ReactNode } from 'react';
import { createPortal } from 'react-dom';

type NewsBlockDragOverlayPortalProps = {
  children: ReactNode;
};

/** Portals drag overlay to body so position:fixed uses the viewport, not backdrop-filter ancestors. */
export function NewsBlockDragOverlayPortal({ children }: NewsBlockDragOverlayPortalProps) {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return null;
  }

  return createPortal(children, document.body);
}
