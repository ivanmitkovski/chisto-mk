/** Points granted when a user's approved report is the first on a site (co-reports earn 0). */
export const POINTS_FIRST_REPORT = 25;

/** Organizer receives this when a citizen-created event goes PENDING → APPROVED (moderation). */
export const POINTS_EVENT_ORGANIZER_APPROVED = 10;

/** Participant joins an approved event (one grant per user per event; may be reversed on completion if no check-in). */
export const POINTS_EVENT_JOINED = 5;

/** Successful check-in (QR redeem or organizer manual check-in for that user). Higher than {@link POINTS_FIRST_REPORT} — field attendance costs more effort than reporting. */
export const POINTS_EVENT_CHECK_IN = 35;

/** Checked-in participants when organizer marks the event COMPLETED. */
export const POINTS_EVENT_COMPLETED = 30;

/** @deprecated Legacy reason codes kept for existing PointTransaction rows in DB. */
export const REASON_ECO_ACTION_APPROVED = 'ECO_ACTION_APPROVED' as const;

/** @deprecated Legacy reason codes kept for existing PointTransaction rows in DB. */
export const REASON_ECO_ACTION_REALIZED = 'ECO_ACTION_REALIZED' as const;

/** `PointTransaction.reasonCode` — organizer’s event approved by moderation. */
export const REASON_EVENT_ORGANIZER_APPROVED = 'EVENT_ORGANIZER_APPROVED' as const;

/** `PointTransaction.reasonCode` — user joined an event. */
export const REASON_EVENT_JOINED = 'EVENT_JOINED' as const;

/** `PointTransaction.reasonCode` — join bonus removed at event completion (no check-in recorded). */
export const REASON_EVENT_JOIN_NO_SHOW = 'EVENT_JOIN_NO_SHOW' as const;

/** `PointTransaction.reasonCode` — user checked in at an in-progress event. */
export const REASON_EVENT_CHECK_IN = 'EVENT_CHECK_IN' as const;

/** `PointTransaction.reasonCode` — completion bonus for checked-in participants. */
export const REASON_EVENT_COMPLETED = 'EVENT_COMPLETED' as const;

/** Organizer receives this once after passing the organizer toolkit quiz. */
export const POINTS_ORGANIZER_CERTIFIED = 15;

/** `PointTransaction.reasonCode` — organizer completed the toolkit certification quiz. */
export const REASON_ORGANIZER_CERTIFIED = 'ORGANIZER_CERTIFIED' as const;
