export type ReportCreditsConfig = {
  dailyCredits: number;
  emergencyWindowHours: number;
  refillIntervalHours: number;
};

export type FeedRankingConfig = {
  defaultVariant: string;
  experimentEnabled: boolean;
};

export type AppConfigSnapshot = {
  reportCredits: ReportCreditsConfig;
  feedRanking: FeedRankingConfig;
  termsVersion: string;
  organizerQuiz: Record<string, unknown>;
};
