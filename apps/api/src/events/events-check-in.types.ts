export interface RedeemResult {
  status: 'pending_confirmation' | 'already_checked_in';
  pendingId?: string;
  expiresAt?: string;
  checkedInAt?: string;
  pointsAwarded?: number;
}

export interface ResolveResult {
  checkedInAt: string;
  pointsAwarded: number;
  userId: string;
  displayName: string;
}
