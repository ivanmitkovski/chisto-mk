import { adminBrowserFetch } from '@/lib/admin-browser-api';

export type SiteMapRow = {
  id: string;
  latitude: number;
  longitude: number;
  status: string;
  description: string | null;
  reportCount: number;
  createdAt: string;
  updatedAt?: string;
  latestReportDescription?: string | null;
  latestReportCategory?: string | null;
  latestReportCreatedAt?: string | null;
  latestReportNumber?: string | null;
  latestReportMediaUrls?: string[];
  distanceKm?: number;
};

type MapResponse = {
  data: SiteMapRow[];
};

export async function fetchSitesForMap(params: {
  lat: number;
  lng: number;
  radiusKm: number;
  status?: string;
}): Promise<MapResponse> {
  const search = new URLSearchParams({
    lat: String(params.lat),
    lng: String(params.lng),
    radiusKm: String(params.radiusKm),
    limit: '200',
  });
  if (params.status) {
    search.set('status', params.status);
  }
  return adminBrowserFetch<MapResponse>(`/sites/map?${search.toString()}`);
}
