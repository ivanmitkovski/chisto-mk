export const SITE_STATUSES = [
  'REPORTED',
  'VERIFIED',
  'CLEANUP_SCHEDULED',
  'IN_PROGRESS',
  'CLEANED',
  'DISPUTED',
] as const;

export type SiteStatus = (typeof SITE_STATUSES)[number];

export type MapQueryMode = 'viewport' | 'radius';

export type MapListApiRow = {
  id: string;
  latitude: number;
  longitude: number;
  address: string | null;
  description: string | null;
  status: SiteStatus;
  createdAt: string;
  updatedAt: string;
  reportCount: number;
  latestReportTitle: string | null;
  latestReportDescription: string | null;
  latestReportCategory: string | null;
  latestReportCreatedAt: string | null;
  latestReportNumber: string | null;
  latestReportMediaUrls?: string[];
  upvotesCount: number;
  commentsCount: number;
  savesCount: number;
  sharesCount: number;
  distanceKm?: number;
};

export type MapEnvelopeMeta = {
  signedMediaExpiresAt: string;
  serverTime: string;
  queryMode: MapQueryMode;
  dataVersion: string;
  mapMode?: 'sites' | 'clusters' | 'mixed';
};

export type MapEnvelope = {
  data: MapListApiRow[];
  meta: MapEnvelopeMeta;
};

export type MapClusterBucket = {
  id: string;
  latitude: number;
  longitude: number;
  count: number;
  siteIds: string[];
};

export type MapClustersResponse = {
  data: MapClusterBucket[];
  meta: {
    queryMode: MapQueryMode;
    dataVersion: string;
  };
};

export type MapHeatPoint = {
  latitude: number;
  longitude: number;
  weight: number;
};

export type MapHeatmapResponse = {
  data: MapHeatPoint[];
  meta: {
    queryMode: MapQueryMode;
    dataVersion: string;
  };
};

export type SiteEventType =
  | 'site.created'
  | 'site.updated'
  | 'site.deleted'
  | 'site_created'
  | 'site_updated'
  | 'site_deleted';

export type SiteEventPayload = {
  eventId: string;
  type: SiteEventType;
  siteId: string;
  mutation: string;
};
