import type { SiteStatus } from '../prisma-client';

export type SiteMapSearchItem = {
  id: string;
  latitude: number;
  longitude: number;
  description: string | null;
  address: string | null;
  status: SiteStatus;
  /** Signed URLs from the site's latest report (same contract as feed `latestReportMediaUrls`). */
  latestReportMediaUrls?: string[];
};

export type GeoIntentBounds = {
  label: string;
  minLat: number;
  maxLat: number;
  minLng: number;
  maxLng: number;
};

export type SiteMapSearchResponse = {
  items: SiteMapSearchItem[];
  suggestions: string[];
  geoIntent: GeoIntentBounds | null;
};

export type RawSearchRow = {
  id: string;
  latitude: number;
  longitude: number;
  description: string | null;
  address: string | null;
  status: SiteStatus;
  score: number;
  latestReportMediaUrls: string[] | null;
};
