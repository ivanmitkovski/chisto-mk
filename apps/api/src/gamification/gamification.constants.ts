/** Points granted when a user's approved report is the first on a site (co-reports earn 0). */
export const POINTS_FIRST_REPORT = 25;

/**
 * Points when an eco-action is approved by moderation.
 * Eco-event module: create one PointTransaction per user per eco-action, idempotent by reference.
 */
export const POINTS_ECO_ACTION_APPROVED = 50;

/**
 * Points when an eco-action is realized (completed).
 * Award only after completion; do not stack with approval if product rules forbid double-dip.
 */
export const POINTS_ECO_ACTION_REALIZED = 100;

/** `PointTransaction.reasonCode` — approved eco-action. */
export const REASON_ECO_ACTION_APPROVED = 'ECO_ACTION_APPROVED' as const;

/** `PointTransaction.reasonCode` — completed / realized eco-action. */
export const REASON_ECO_ACTION_REALIZED = 'ECO_ACTION_REALIZED' as const;
