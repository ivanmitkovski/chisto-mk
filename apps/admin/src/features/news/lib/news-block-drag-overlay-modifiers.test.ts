import { describe, expect, it } from 'vitest';
import { applyBlockDragPickupTransform } from './news-block-drag-overlay-modifiers';

describe('applyBlockDragPickupTransform', () => {
  const context = {
    activeTop: 400,
    pickupOffsetY: 18,
    activationDeltaY: 0,
  };
  const activator = { x: 120, y: 418 };
  const baseTransform = { x: 0, y: 40, scaleX: 1, scaleY: 1 };

  it('keeps the pickup point under the pointer while dragging', () => {
    const result = applyBlockDragPickupTransform(baseTransform, context, activator);

    expect(result.y).toBe(40);
    expect(result.x).toBe(0);
  });

  it('compensates activation-constraint movement on the first frame', () => {
    const result = applyBlockDragPickupTransform(
      { x: 0, y: 0, scaleX: 1, scaleY: 1 },
      { ...context, pickupOffsetY: 26, activationDeltaY: 8 },
      activator,
    );

    expect(result.y).toBe(0);
  });

  it('does not vertically center tall blocks on the cursor', () => {
    const tallContext = { ...context, pickupOffsetY: 12 };
    const moved = applyBlockDragPickupTransform(
      { x: 0, y: 100, scaleX: 1, scaleY: 1 },
      tallContext,
      { x: 120, y: 412 },
    );

    expect(moved.y).toBe(100);
  });

  it('returns the original transform when pickup context is missing', () => {
    expect(applyBlockDragPickupTransform(baseTransform, null, activator)).toEqual(baseTransform);
  });
});
