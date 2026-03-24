'use client';

import { useQuery } from '@tanstack/react-query';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { fetchSitesForMap } from '../data/map-adapter';
import { MACEDONIA_CENTER, INITIAL_ZOOM } from '../map-constants';

/** Approximate radius in km for a zoom level (Leaflet) */
function radiusKmFromZoom(zoom: number): number {
  const lookup: Record<number, number> = {
    6: 260,
    7: 180,
    8: 120,
    9: 90,
    10: 60,
    11: 40,
    12: 28,
    13: 20,
    14: 14,
    15: 10,
    16: 7,
    17: 5,
    18: 3,
  };
  const z = Math.round(Math.min(18, Math.max(6, zoom)));
  return lookup[z] ?? 80;
}

export function useSitesMap() {
  const searchParams = useSearchParams();
  const statusFromUrl = searchParams.get('status') ?? '';
  const [center, setCenter] = useState<[number, number]>([...MACEDONIA_CENTER]);
  const [zoom, setZoom] = useState(INITIAL_ZOOM);
  const [statusFilter, setStatusFilter] = useState(statusFromUrl || '');

  useEffect(() => {
    const s = searchParams.get('status') ?? '';
    setStatusFilter(s);
  }, [searchParams]);

  const [selectedSiteId, setSelectedSiteId] = useState<string | null>(null);

  const radiusKm = useMemo(() => radiusKmFromZoom(zoom), [zoom]);

  const queryKey = useMemo(
    () => ['sites-map', center[0], center[1], radiusKm, statusFilter || 'all'] as const,
    [center, radiusKm, statusFilter],
  );

  const { data, isLoading, isFetching, isError, refetch } = useQuery({
    queryKey,
    queryFn: () =>
      fetchSitesForMap({
        lat: center[0],
        lng: center[1],
        radiusKm,
        ...(statusFilter ? { status: statusFilter } : {}),
      }),
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
