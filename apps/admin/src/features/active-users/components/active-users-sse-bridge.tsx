'use client';

import { useEffect } from 'react';
import { useActiveUsersLive } from '../hooks/use-active-users-live';

export function ActiveUsersSseBridge() {
  const { applySseSummary, pushFeedItem } = useActiveUsersLive();

  useEffect(() => {
    const handler = (event: Event) => {
      const custom = event as CustomEvent<{ type?: string; summary?: Record<string, number>; event?: ActivityFeedItem }>;
      const data = custom.detail;
      if (!data?.type) return;
      if (data.type === 'active_users_updated' && data.summary) {
        applySseSummary({
          currentActive: data.summary.currentActive,
          online: data.summary.online,
          away: data.summary.away,
          peakToday: data.summary.peakToday,
        });
      }
      if (data.type === 'activity_event' && data.event) {
        pushFeedItem(data.event);
      }
    };
    window.addEventListener('chisto:active-users-sse', handler);
    return () => window.removeEventListener('chisto:active-users-sse', handler);
  }, [applySseSummary, pushFeedItem]);

  return null;
}

type ActivityFeedItem = import('../data/active-users.types').ActivityFeedItem;
