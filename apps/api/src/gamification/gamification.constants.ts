/** @deprecated Legacy: was first-approved-on-site bonus as a separate grant. Pioneer bonus is now part of {@link REASON_REPORT_APPROVED} metadata. */
export const POINTS_FIRST_REPORT = 25;

/** Organizer receives this when a citizen-created event goes PENDING → APPROVED (moderation). */
export const POINTS_EVENT_ORGANIZER_APPROVED = 10;

/** Participant joins an approved event (one grant per user per event; may be reversed on completion if no check-in). */
export const POINTS_EVENT_JOINED = 5;

/** Successful check-in (QR redeem or organizer manual check-in for that user). Field attendance costs more effort than a typical approved report. */
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

/** `PointTransaction.reasonCode` — organizer removed a check-in; reverses {@link REASON_EVENT_CHECK_IN} if present. */
export const REASON_EVENT_CHECK_IN_REMOVED = 'EVENT_CHECK_IN_REMOVED' as const;

/** `PointTransaction.reasonCode` — user left before the event; reverses {@link REASON_EVENT_JOINED} if present. */
export const REASON_EVENT_JOIN_LEFT = 'EVENT_JOIN_LEFT' as const;

/** `PointTransaction.reasonCode` — completion bonus for checked-in participants. */
export const REASON_EVENT_COMPLETED = 'EVENT_COMPLETED' as const;

/** Organizer receives this once after passing the organizer toolkit quiz. */
export const POINTS_ORGANIZER_CERTIFIED = 15;

/** `PointTransaction.reasonCode` — organizer completed the toolkit certification quiz. */
export const REASON_ORGANIZER_CERTIFIED = 'ORGANIZER_CERTIFIED' as const;

/**
 * @deprecated No longer written on new submits. Existing DB rows kept. Use {@link REASON_REPORT_APPROVED}.
 */
export const REASON_REPORT_SUBMITTED = 'REPORT_SUBMITTED' as const;

/** Single idempotent grant per report when moderation (or duplicate merge) sets status to APPROVED. */
export const REASON_REPORT_APPROVED = 'REPORT_APPROVED' as const;

/** One-time clawback when an APPROVED report is moved to DELETED. */
export const REASON_REPORT_APPROVAL_REVOKED = 'REPORT_APPROVAL_REVOKED' as const;

/** Max positive points from {@link REASON_REPORT_APPROVED} per user per Skopje calendar day. */
export const DAILY_REPORT_APPROVAL_POINTS_CAP = 80;

/** `PointTransaction.metadata.version` for report approval grants. */
export const REPORT_APPROVAL_POINTS_METADATA_VERSION = 1;

/** Base points inside the approval bundle (before repeat-site multiplier / pioneer). */
export const REPORT_APPROVAL_POINTS_BASE = 8;

/** Per photo in approval bundle, before cap. */
export const REPORT_APPROVAL_POINTS_MEDIA_PER_PHOTO = 1;

/** Max photos counted toward media points. */
export const REPORT_APPROVAL_POINTS_MEDIA_PER_PHOTO_MAX = 5;

/** Severity ≥ this adds {@link REPORT_APPROVAL_POINTS_SEVERITY_BONUS}. */
export const REPORT_APPROVAL_POINTS_SEVERITY_THRESHOLD = 4;

export const REPORT_APPROVAL_POINTS_SEVERITY_BONUS = 4;

/** When cleanup effort is set and not NOT_SURE. */
export const REPORT_APPROVAL_POINTS_CLEANUP_EFFORT = 3;

/** Extra points when this is the first APPROVED report on the site. */
export const REPORT_APPROVAL_POINTS_SITE_PIONEER = 18;

/** Multiplier on nominal core (base+media+severity+effort) when the site already has other approved reports. */
export const REPORT_APPROVED_REPEAT_SITE_MULTIPLIER = 0.55;
