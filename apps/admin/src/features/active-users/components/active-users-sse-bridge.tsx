'use client';

import { useEffect } from 'react';
import { useTranslations } from 'next-intl';
import { useToast } from '@/components/ui';
import { useActiveUsersLive } from '../hooks/use-active-users-live';
import type { ActiveUsersSummary, ActivityFeedItem } from '../data/active-users.types';

type SseSummaryPayload = Pick<
  ActiveUsersSummary,
  'currentActive' | 'online' | 'away' | 'peakToday'
>;

type ActiveUsersSseDetail =
  | { type: 'active_users_updated'; summary: SseSummaryPayload }
  | { type: 'activity_event'; event: ActivityFeedItem }
  | { type: 'alert_triggered'; ruleId?: string; metric?: string; threshold?: number };

function parseSseDetail(detail: unknown): ActiveUsersSseDetail | null {
  if (!detail || typeof detail !== 'object') return null;
  const d = detail as Record<string, unknown>;
  const type = d.type;
  if (type === 'active_users_updated' && d.summary && typeof d.summary === 'object') {
    const s = d.summary as Record<string, unknown>;
    return {
      type: 'active_users_updated',
      summary: {
        currentActive: Number(s.currentActive ?? 0),
        online: Number(s.online ?? 0),
        away: Number(s.away ?? 0),
        peakToday: Number(s.peakToday ?? 0),
      },
    };
  }
  if (type === 'activity_event' && d.event && typeof d.event === 'object') {
    return { type: 'activity_event', event: d.event as ActivityFeedItem };
  }
  if (type === 'alert_triggered') {
    return {
      type: 'alert_triggered',
      ...(typeof d.ruleId === 'string' ? { ruleId: d.ruleId } : {}),
      ...(typeof d.metric === 'string' ? { metric: d.metric } : {}),
      ...(typeof d.threshold === 'number' ? { threshold: d.threshold } : {}),
    };
  }
  return null;
}

export function ActiveUsersSseBridge() {
  const t = useTranslations('activeUsers');
  const { showToast } = useToast();
  const { applySseSummary, pushFeedItem, setHighlightedAlertId } = useActiveUsersLive();

  useEffect(() => {
    const handler = (event: Event) => {
      const custom = event as CustomEvent<unknown>;
      const parsed = parseSseDetail(custom.detail);
      if (!parsed) return;

      if (parsed.type === 'active_users_updated') {
        applySseSummary(parsed.summary);
      }
      if (parsed.type === 'activity_event') {
        pushFeedItem(parsed.event);
      }
      if (parsed.type === 'alert_triggered') {
        if (parsed.ruleId) {
          setHighlightedAlertId(parsed.ruleId);
          window.setTimeout(() => setHighlightedAlertId(null), 4000);
        }
        showToast({
          tone: 'warning',
          title: t('alerts.triggeredTitle'),
          message: t('alerts.triggeredMessage', {
            metric: parsed.metric ?? '—',
            threshold: parsed.threshold ?? '—',
          }),
        });
      }
    };
    window.addEventListener('chisto:active-users-sse', handler);
    return () => window.removeEventListener('chisto:active-users-sse', handler);
  }, [applySseSummary, pushFeedItem, setHighlightedAlertId, showToast, t]);

  return null;
}
