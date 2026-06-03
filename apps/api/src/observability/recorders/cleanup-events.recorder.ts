let cleanupEventStaffPendingSignals = 0;
let cleanupEventPublishedAudienceNotified = 0;
let cleanupEventModerationApproved = 0;

export function recordCleanupEventStaffPendingSignals(count: number): void {
  cleanupEventStaffPendingSignals += Math.max(0, count);
}

export function recordCleanupEventPublishedAudienceBatch(count: number): void {
  cleanupEventPublishedAudienceNotified += Math.max(0, count);
}

export function recordCleanupEventModerationApproved(): void {
  cleanupEventModerationApproved += 1;
}

export function snapshot() {
  return {
    cleanupEventStaffPendingSignals,
    cleanupEventPublishedAudienceNotified,
    cleanupEventModerationApproved,
  };
}
