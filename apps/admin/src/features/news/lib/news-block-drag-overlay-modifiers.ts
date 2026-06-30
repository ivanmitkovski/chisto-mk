import type { Modifier } from '@dnd-kit/core';
import { getEventCoordinates } from '@dnd-kit/utilities';

export type BlockDragPickupContext = {
  /** Frozen row top (viewport) at pickup. */
  activeTop: number;
  /** Pointer Y minus row top at the moment drag became active. */
  pickupOffsetY: number;
  /** Pointer movement during activation constraint before drag became visible. */
  activationDeltaY: number;
};

let pickupContext: BlockDragPickupContext | null = null;

export function setBlockDragPickupContext(context: BlockDragPickupContext | null): void {
  pickupContext = context;
}

export function getBlockDragPickupContext(): BlockDragPickupContext | null {
  return pickupContext;
}

export function applyBlockDragPickupTransform(
  transform: { x: number; y: number; scaleX: number; scaleY: number },
  context: BlockDragPickupContext | null,
  activator: { x: number; y: number } | null,
): { x: number; y: number; scaleX: number; scaleY: number } {
  if (!context || !activator) {
    return transform;
  }

  const pointerY = activator.y + context.activationDeltaY + transform.y;
  const desiredTop = pointerY - context.pickupOffsetY;

  return {
    ...transform,
    x: 0,
    y: desiredTop - context.activeTop,
  };
}

/**
 * Anchors the overlay to the handle pickup point.
 * Required when DragOverlay is portaled to document.body (outside backdrop-filter ancestors).
 */
export const snapBlockOverlayToPickup: Modifier = ({ activatorEvent, transform }) => {
  const activator = activatorEvent ? getEventCoordinates(activatorEvent) : null;
  return applyBlockDragPickupTransform(transform, pickupContext, activator);
};
