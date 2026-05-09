import type {
  MapEnvelope as SharedMapEnvelope,
  MapListApiRow as SharedMapListApiRow,
  MapQueryMode as SharedMapQueryMode,
} from '@chisto/map-contracts';

export type MapQueryMode = SharedMapQueryMode;

export type MapProjectionRow = {
  siteId: string;
  latitude: number;
  longitude: number;
  address: string | null;
  description: string | null;
  status: string;
  thumbnailUrl: string | null;
  pollutionCategory: string | null;
  latestReportTitle: string | null;
  latestReportDescription: string | null;
  latestReportNumber: string | null;
  latestReportAt: Date | null;
  reportCount: number;
  upvotesCount: number;
  commentsCount: number;
  savesCount: number;
  sharesCount: number;
  siteCreatedAt: Date;
  siteUpdatedAt: Date;
};

export type MapSiteRow = MapProjectionRow;
export type MapSiteLiteRow = MapProjectionRow;
export type MapListApiRow = SharedMapListApiRow;

export type MapResponse = SharedMapEnvelope & {
  data: MapListApiRow[];
};
