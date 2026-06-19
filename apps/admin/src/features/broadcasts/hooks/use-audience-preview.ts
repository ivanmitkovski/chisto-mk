'use client';

import { useEffect, useMemo, useState } from 'react';
import { ADMIN_SEARCH_DEBOUNCE_MS } from '@/lib/utils/admin-ui-timing';
import { previewBroadcastAudience } from '../data/broadcast-audience-api';
import type { BroadcastAudience } from '../types';

type UseAudiencePreviewOptions = {
  audience: BroadcastAudience;
  audienceUserIds: string[];
  enabled?: boolean;
};

export function useAudiencePreview({ audience, audienceUserIds, enabled = true }: UseAudiencePreviewOptions) {
  const [preview, setPreview] = useState<{ recipientCount: number; capped: boolean; cap: number } | null>(null);
  const [loading, setLoading] = useState(false);
  const userIdsKey = useMemo(() => audienceUserIds.join(','), [audienceUserIds]);

  useEffect(() => {
    if (!enabled) {
      setPreview(null);
      return;
    }

    let cancelled = false;
    const timer = window.setTimeout(() => {
      void (async () => {
        setLoading(true);
        try {
          const ids = userIdsKey ? userIdsKey.split(',').filter(Boolean) : [];
          const result = await previewBroadcastAudience({
            audience,
            ...(audience === 'users' ? { audienceUserIds: ids } : {}),
          });
          if (!cancelled) {
            setPreview(result);
          }
        } catch {
          if (!cancelled) {
            setPreview(null);
          }
        } finally {
          if (!cancelled) {
            setLoading(false);
          }
        }
      })();
    }, ADMIN_SEARCH_DEBOUNCE_MS);

    return () => {
      cancelled = true;
      window.clearTimeout(timer);
    };
  }, [audience, userIdsKey, enabled]);

  return { preview, loading };
}
