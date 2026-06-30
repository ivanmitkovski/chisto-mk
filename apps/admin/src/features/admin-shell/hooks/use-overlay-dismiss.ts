import { RefObject, useEffect } from 'react';

type UseOverlayDismissOptions = {
  isOpen: boolean;
  containerRef: RefObject<HTMLElement | null>;
  triggerRef?: RefObject<HTMLElement | null> | undefined;
  onDismiss: () => void;
  closeOnEscape?: boolean;
  closeOnOutsidePointer?: boolean;
};

export function useOverlayDismiss({
  isOpen,
  containerRef,
  triggerRef,
  onDismiss,
  closeOnEscape = true,
  closeOnOutsidePointer = true,
}: UseOverlayDismissOptions) {
  useEffect(() => {
    if (!isOpen) {
      return;
    }

    const onPointerDown = (event: PointerEvent) => {
      if (!closeOnOutsidePointer) {
        return;
      }

      const target = event.target as Node;
      const containerElement = containerRef.current;
      const triggerElement = triggerRef?.current;

      if (!containerElement) {
        return;
      }

      if (containerElement.contains(target)) {
        return;
      }

      if (triggerElement?.contains(target)) {
        return;
      }

      onDismiss();
    };

    const onKeyDown = (event: KeyboardEvent) => {
      if (!closeOnEscape) {
        return;
      }

      if (event.key !== 'Escape') {
        return;
      }

      onDismiss();
    };

    window.addEventListener('pointerdown', onPointerDown);
    window.addEventListener('keydown', onKeyDown);

    return () => {
      window.removeEventListener('pointerdown', onPointerDown);
      window.removeEventListener('keydown', onKeyDown);
    };
  }, [closeOnEscape, closeOnOutsidePointer, containerRef, isOpen, onDismiss, triggerRef]);
}
