import { adminNavigation } from '../config/navigation';
import { NAV_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import type { CommandDefinition } from './types';

const NAV_KEY_TO_GO_PREFIX: Record<string, string> = {
  dashboard: 'goDashboard',
  reports: 'goReports',
  duplicates: 'goDuplicates',
  users: 'goUsers',
  sites: 'goSites',
  resolutions: 'goResolutions',
  map: 'goMap',
  events: 'goEvents',
  'risk-signals': 'goRiskSignals',
  moderation: 'goModeration',
  broadcasts: 'goBroadcasts',
  news: 'goNews',
  team: 'goTeam',
  gamification: 'goGamification',
  'app-config': 'goAppConfig',
  operations: 'goOperations',
  'active-users': 'goActiveUsers',
  'email-suppressions': 'goEmailSuppressions',
  'webhook-logs': 'goWebhookLogs',
  audit: 'goAudit',
  notifications: 'goNotifications',
  settings: 'goSettings',
};

function hrefSegments(href: string): string[] {
  return href
    .split('/')
    .filter(Boolean)
    .map((segment) => segment.replace(/-/g, ' '));
}

export function buildNavigationCommands(): CommandDefinition[] {
  return adminNavigation.map((item) => {
    const goKey = NAV_KEY_TO_GO_PREFIX[item.key];
    if (!goKey) {
      throw new Error(`Missing command label mapping for nav key: ${item.key}`);
    }

    const permission = NAV_PERMISSIONS[item.key];
    if (!permission) {
      throw new Error(`Missing NAV_PERMISSIONS entry for nav key: ${item.key}`);
    }

    return {
      id: `go-${item.key}`,
      group: 'navigation' as const,
      labelKey: `commands.${goKey}.label`,
      descriptionKey: `commands.${goKey}.description`,
      messageNamespace: 'nav' as const,
      icon: item.icon,
      keywords: hrefSegments(item.href),
      permission,
      href: item.href,
      action: { type: 'navigate', href: item.href },
    };
  });
}

/** Used by structure check — nav keys must match palette navigation commands. */
export function getNavigationCommandIds(): string[] {
  return adminNavigation.map((item) => `go-${item.key}`);
}
