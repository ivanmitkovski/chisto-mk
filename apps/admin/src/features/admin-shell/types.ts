import { IconName } from '@/components/ui';

export type NavItemKey =
  | 'dashboard'
  | 'reports'
  | 'duplicates'
  | 'users'
  | 'sites'
  | 'resolutions'
  | 'map'
  | 'events'
  | 'risk-signals'
  | 'moderation'
  | 'operations'
  | 'active-users'
  | 'broadcasts'
  | 'gamification'
  | 'app-config'
  | 'audit'
  | 'notifications'
  | 'email-suppressions'
  | 'webhook-logs'
  | 'team'
  | 'settings';

export type NavItem = {
  key: NavItemKey;
  /** Translation key under the `nav` namespace (defaults to `key`). */
  labelKey?: NavItemKey | string;
  href: string;
  icon: IconName;
};
