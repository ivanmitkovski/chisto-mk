export type SiteShareReporter = {
  displayLabel: string | null;
  avatarUrl: string | null;
  isDeleted: boolean;
  isAnonymous?: boolean;
};

export type SiteShareEvent = {
  id: string;
  title: string;
  scheduledAt: string;
  city: string;
  participantCount: number;
  maxParticipants: number | null;
  status: string;
};

export type SiteShareCard = {
  id: string;
  title: string;
  siteLabel: string;
  status: string;
  description: string | null;
  address: string | null;
  latitude: number;
  longitude: number;
  mediaUrls: string[];
  category: string | null;
  severity: number | null;
  cleanupEffort: string | null;
  upvotesCount: number;
  commentsCount: number;
  sharesCount: number;
  savesCount: number;
  reportedAt: string | null;
  reporter: SiteShareReporter | null;
  events: SiteShareEvent[];
  cleanupEvidenceUrls: string[];
  ogImageUrl: string | null;
};
