'use client';

import { useEffect, useRef } from 'react';

function isInternalNavigationHref(href: string): boolean {
  if (!href || href.startsWith('#')) return false;
  if (href.startsWith('mailto:') || href.startsWith('tel:')) return false;
  if (href.startsWith('http://') || href.startsWith('https://')) return false;
  return href.startsWith('/');
}

export function useUnsavedChangesGuard(isDirty: boolean, message = 'You have unsaved changes. Leave anyway?') {
  const isDirtyRef = useRef(isDirty);
  isDirtyRef.current = isDirty;

  useEffect(() => {
    function onBeforeUnload(event: BeforeUnloadEvent) {
      if (!isDirtyRef.current) return;
      event.preventDefault();
      event.returnValue = message;
    }

    function confirmLeave(): boolean {
      if (!isDirtyRef.current) return true;
      return window.confirm(message);
    }

    function onDocumentClick(event: MouseEvent) {
      if (!isDirtyRef.current) return;
      if (event.defaultPrevented) return;
      if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;

      const target = event.target;
      if (!(target instanceof Element)) return;
      const anchor = target.closest('a');
      if (!anchor || anchor.target === '_blank') return;

      const href = anchor.getAttribute('href');
      if (!href || !isInternalNavigationHref(href)) return;

      if (!confirmLeave()) {
        event.preventDefault();
        event.stopPropagation();
      }
    }

    function onPopState() {
      if (!isDirtyRef.current) return;
      if (!confirmLeave()) {
        history.pushState(null, '', window.location.href);
      }
    }

    window.addEventListener('beforeunload', onBeforeUnload);
    document.addEventListener('click', onDocumentClick, true);
    window.addEventListener('popstate', onPopState);

    return () => {
      window.removeEventListener('beforeunload', onBeforeUnload);
      document.removeEventListener('click', onDocumentClick, true);
      window.removeEventListener('popstate', onPopState);
    };
  }, [message]);
}
