import { useCallback, useRef, useState, type PointerEvent as ReactPointerEvent } from "react";

const TAP_MOVE_PX = 8;
const TAP_MAX_MS = 300;
const SWIPE_HORIZONTAL_PX = 56;
const SWIPE_VERTICAL_PX = 80;
const VELOCITY_PX_MS = 0.4;
const DISMISS_FADE_DISTANCE = 300;

function trySetPointerCapture(target: EventTarget, pointerId: number) {
  if (typeof (target as HTMLElement).setPointerCapture === "function") {
    (target as HTMLElement).setPointerCapture(pointerId);
  }
}

function tryReleasePointerCapture(target: EventTarget, pointerId: number) {
  if (typeof (target as HTMLElement).releasePointerCapture === "function") {
    try {
      (target as HTMLElement).releasePointerCapture(pointerId);
    } catch {
      // Already released.
    }
  }
}

export type ImageViewerGestureHandlers = {
  onPointerDown: (e: ReactPointerEvent<HTMLElement>) => void;
  onPointerMove: (e: ReactPointerEvent<HTMLElement>) => void;
  onPointerUp: (e: ReactPointerEvent<HTMLElement>) => void;
  onPointerCancel: (e: ReactPointerEvent<HTMLElement>) => void;
};

export type UseImageViewerGesturesOptions = {
  enabled: boolean;
  canNavigate: boolean;
  reduceMotion: boolean;
  onNext: () => void;
  onPrevious: () => void;
  onDismiss: () => void;
  onTap: () => void;
};

export type UseImageViewerGesturesResult = {
  handlers: ImageViewerGestureHandlers;
  dragY: number;
  dragOpacity: number;
  isDragging: boolean;
};

type GestureState = {
  pointerId: number;
  startX: number;
  startY: number;
  startTime: number;
  lastX: number;
  lastY: number;
  lastTime: number;
};

/**
 * Pointer-based gestures for ImageViewer:
 * - horizontal swipe → next/prev (when canNavigate)
 * - vertical swipe down → dismiss (with dragY for visual feedback)
 * - tap → onTap (chrome toggle); does not dismiss
 */
export function useImageViewerGestures({
  enabled,
  canNavigate,
  reduceMotion,
  onNext,
  onPrevious,
  onDismiss,
  onTap,
}: UseImageViewerGesturesOptions): UseImageViewerGesturesResult {
  const gestureRef = useRef<GestureState | null>(null);
  const [dragY, setDragY] = useState(0);
  const [isDragging, setIsDragging] = useState(false);

  const resetDrag = useCallback(() => {
    setDragY(0);
    setIsDragging(false);
  }, []);

  const endGesture = useCallback(
    (e: ReactPointerEvent<HTMLElement>) => {
      const g = gestureRef.current;
      if (!g || g.pointerId !== e.pointerId) return;
      gestureRef.current = null;

      tryReleasePointerCapture(e.currentTarget, e.pointerId);

      const dx = e.clientX - g.startX;
      const dy = e.clientY - g.startY;
      const dt = Math.max(1, e.timeStamp - g.startTime);
      const dist = Math.hypot(dx, dy);
      const vx = Math.abs(dx) / dt;
      const vy = Math.abs(dy) / dt;

      if (dist < TAP_MOVE_PX && dt < TAP_MAX_MS) {
        resetDrag();
        onTap();
        return;
      }

      const horizontal = Math.abs(dx) > Math.abs(dy);
      if (horizontal && canNavigate) {
        if (Math.abs(dx) > SWIPE_HORIZONTAL_PX || vx > VELOCITY_PX_MS) {
          resetDrag();
          if (dx < 0) onNext();
          else onPrevious();
          return;
        }
      } else if (!horizontal && dy > 0) {
        if (dy > SWIPE_VERTICAL_PX || vy > VELOCITY_PX_MS) {
          resetDrag();
          onDismiss();
          return;
        }
      }

      resetDrag();
    },
    [canNavigate, onDismiss, onNext, onPrevious, onTap, resetDrag],
  );

  const onPointerDown = useCallback(
    (e: ReactPointerEvent<HTMLElement>) => {
      if (!enabled || e.button !== 0) return;
      // Ignore multi-touch / secondary pointers.
      if (gestureRef.current) return;
      trySetPointerCapture(e.currentTarget, e.pointerId);
      gestureRef.current = {
        pointerId: e.pointerId,
        startX: e.clientX,
        startY: e.clientY,
        startTime: e.timeStamp,
        lastX: e.clientX,
        lastY: e.clientY,
        lastTime: e.timeStamp,
      };
      setIsDragging(true);
    },
    [enabled],
  );

  const onPointerMove = useCallback(
    (e: ReactPointerEvent<HTMLElement>) => {
      const g = gestureRef.current;
      if (!g || g.pointerId !== e.pointerId) return;

      g.lastX = e.clientX;
      g.lastY = e.clientY;
      g.lastTime = e.timeStamp;

      const dx = e.clientX - g.startX;
      const dy = e.clientY - g.startY;

      // Only show vertical dismiss drag when clearly vertical and downward.
      if (!reduceMotion && dy > 0 && Math.abs(dy) > Math.abs(dx)) {
        setDragY(dy);
      } else {
        setDragY(0);
      }
    },
    [reduceMotion],
  );

  const onPointerUp = useCallback(
    (e: ReactPointerEvent<HTMLElement>) => {
      endGesture(e);
    },
    [endGesture],
  );

  const onPointerCancel = useCallback(
    (e: ReactPointerEvent<HTMLElement>) => {
      const g = gestureRef.current;
      if (!g || g.pointerId !== e.pointerId) return;
      gestureRef.current = null;
      tryReleasePointerCapture(e.currentTarget, e.pointerId);
      resetDrag();
    },
    [resetDrag],
  );

  const dragOpacity = Math.max(0.35, 1 - dragY / DISMISS_FADE_DISTANCE);

  return {
    handlers: {
      onPointerDown,
      onPointerMove,
      onPointerUp,
      onPointerCancel,
    },
    dragY: reduceMotion ? 0 : dragY,
    dragOpacity: reduceMotion ? 1 : dragOpacity,
    isDragging,
  };
}
