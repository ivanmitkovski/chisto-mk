'use client';

import { useQuery } from '@tanstack/react-query';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { usePathname, useRouter, useSearchParams } from 'next/navigation';
import { fetchClustersForMap, fetchSitesForMap } from '../data/map-adapter';
import { SERVER_CLUSTER_MAX_ZOOM } from '../map-constants';
import { parseViewportFromSearchParams, radiusKmFromZoom } from './map-viewport-url';

export function useSitesMap() {
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const router = useRouter();
  const statusFromUrl = searchParams.get('status') ?? '';
  const includeArchivedFromUrl = searchParams.get('includeArchived') === 'true';
  const [center, setCenter] = useState<[number, number]>(() =>
    parseViewportFromSearchParams(new URLSearchParams(searchParams.toString())).center,
  );
  const [zoom, setZoom] = useState(
    () => parseViewportFromSearchParams(new URLSearchParams(searchParams.toString())).zoom,
  );
  const [statusFilter, setStatusFilter] = useState(statusFromUrl || '');
  const [includeArchived, setIncludeArchived] = useState(includeArchivedFromUrl);

  useEffect(() => {
    const s = searchParams.get('status') ?? '';
    setStatusFilter(s);
    setIncludeArchived(searchParams.get('includeArchived') === 'true');
  }, [searchParams]);

  /** Only when the URL carries explicit viewport coords (avoids clobbering pan on filter-only changes). */
  const viewportSearchKey = useMemo(() => {
    const lat = searchParams.get('lat');
    const lng = searchParams.get('lng');
    if (lat == null || lat === '' || lng == null || lng === '') {
      return null;
    }
    return `${lat}|${lng}|${searchParams.get('z') ?? ''}`;
  }, [searchParams]);

  useEffect(() => {
    if (!viewportSearchKey) {
      return;
    }
    const parsed = parseViewportFromSearchParams(new URLSearchParams(searchParams.toString()));
    setCenter((prev) => {
      const drift =
          Math.abs(parsed.center[0] - prev[0]) + Math.abs(parsed.center[1] - prev[1]);
      return drift < 1e-7 ? prev : parsed.center;
    });
    setZoom((prev) => (parsed.zoom === prev ? prev : parsed.zoom));
  }, [viewportSearchKey, searchParams]);

  useEffect(() => {
    const lat = center[0].toFixed(5);
    const lng = center[1].toFixed(5);
    const z = String(zoom);
    if (
      searchParams.get('lat') === lat &&
      searchParams.get('lng') === lng &&
      searchParams.get('z') === z
    ) {
      return;
    }
    const sp = new URLSearchParams(searchParams.toString());
    sp.set('lat', lat);
    sp.set('lng', lng);
    sp.set('z', z);
    router.replace(`${pathname}?${sp.toString()}`, { scroll: false });
  }, [center, zoom, pathname, router, searchParams]);

  const [selectedSiteId, setSelectedSiteId] = useState<string | null>(null);

  const radiusKm = useMemo(() => radiusKmFromZoom(zoom), [zoom]);

  const queryKey = useMemo(
    () => ['sites-map', center[0], center[1], radiusKm, zoom, statusFilter || 'all', includeArchived ? 'archived' : 'hot'] as const,
    [center, radiusKm, zoom, statusFilter, includeArchived],
  );

  const { data, isLoading, isFetching, isError, refetch } = useQuery({
    queryKey,
    queryFn: async () => {
      if (zoom <= SERVER_CLUSTER_MAX_ZOOM) {
        const clusters = await fetchClustersForMap({
          lat: center[0],
          lng: center[1],
          radiusKm,
          zoom,
          ...(statusFilter ? { status: statusFilter } : {}),
          ...(includeArchived ? { includeArchived: true } : {}),
        });
        return {
          data: clusters.data.map((bucket) => ({
            id: `cluster:${bucket.id}`,
            latitude: bucket.latitude,
            longitude: bucket.longitude,
            address: null,
            description: `Cluster (${bucket.count})`,
            status: 'REPORTED' as const,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            reportCount: bucket.count,
            latestReportTitle: null,
            latestReportDescription: null,
            latestReportCategory: null,
            latestReportCreatedAt: null,
            latestReportNumber: null,
            upvotesCount: 0,
            commentsCount: 0,
            savesCount: 0,
            sharesCount: 0,
            isCluster: true,
            clusterSiteIds: bucket.siteIds,
          })),
          meta: {
            signedMediaExpiresAt: new Date(Date.now() + 60_000).toISOString(),
            serverTime: new Date().toISOString(),
            queryMode: 'viewport' as const,
            dataVersion: Date.now().toString(36),
            mapMode: 'clusters' as const,
          },
        };
      }
      return fetchSitesForMap({
        lat: center[0],
        lng: center[1],
        radiusKm,
        zoom,
        detail: 'full',
        ...(statusFilter ? { status: statusFilter } : {}),
        ...(includeArchived ? { includeArchived: true } : {}),
      });
    },
    staleTime: 60_000,
    gcTime: 5 * 60_000,
    placeholderData: (prev) => prev,
    refetchOnWindowFocus: false,
  });

  const sites = data?.data ?? [];
  const selectedSite = useMemo(
    () => sites.find((s) => s.id === selectedSiteId) ?? null,
    [sites, selectedSiteId],
  );

  const updateView = useCallback((newCenter: [number, number], newZoom: number) => {
    setCenter(newCenter);
    setZoom(newZoom);
  }, []);

  const setStatus = useCallback((status: string) => {
    setStatusFilter(status);
  }, []);

  return {
    center,
    zoom,
    radiusKm,
    statusFilter,
    includeArchived,
    selectedSiteId,
    selectedSite,
    sites,
    isLoading,
    isFetching,
    isError,
    refetch,
    setCenter,
    setZoom,
    updateView,
    setStatusFilter: setStatus,
    setSelectedSiteId,
  };
}
