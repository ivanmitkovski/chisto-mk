export type GamificationConfig = {
  levelThresholds: number[];
  pointValues: Record<string, number>;
};

export type WeeklyRankingEntry = {
  rank: number;
  userId: string;
  displayName: string | null;
  email: string | null;
  weeklyPoints: number;
  showOnLeaderboard: boolean;
};

export type WeeklyRankingsResponse = {
  weekStartsAt: string;
  weekEndsAt: string;
  entries: WeeklyRankingEntry[];
};

export type UserPointLedgerEntry = {
  id: string;
  delta: number;
  reasonCode: string;
  note: string | null;
  createdAt: string;
  balanceAfter: number;
};

export type UserPointLedgerResponse = {
  data: UserPointLedgerEntry[];
  meta: { total: number; page: number; limit: number };
};
