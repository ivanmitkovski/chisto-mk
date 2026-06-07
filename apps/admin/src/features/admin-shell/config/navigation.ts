import { NavItem } from '../types';

export const adminNavigation: ReadonlyArray<NavItem> = [
  { key: 'dashboard', href: '/dashboard', icon: 'home' },
  { key: 'reports', href: '/dashboard/reports', icon: 'document-text' },
  { key: 'duplicates', labelKey: 'duplicates', href: '/dashboard/reports/duplicates', icon: 'document-forward' },
  { key: 'users', href: '/dashboard/users', icon: 'users' },
  { key: 'sites', href: '/dashboard/sites', icon: 'location' },
  { key: 'map', href: '/dashboard/map', icon: 'map' },
  { key: 'events', href: '/dashboard/events', icon: 'calendar' },
  { key: 'risk-signals', href: '/dashboard/events/risk-signals', icon: 'alert-triangle' },
  { key: 'moderation', href: '/dashboard/moderation/ugc', icon: 'clipboard-close' },
  { key: 'broadcasts', href: '/dashboard/broadcasts', icon: 'megaphone' },
  { key: 'team', href: '/dashboard/team', icon: 'user-cog' },
  { key: 'gamification', href: '/dashboard/gamification', icon: 'trophy' },
  { key: 'app-config', href: '/dashboard/app-config', icon: 'sliders' },
  { key: 'operations', href: '/dashboard/operations', icon: 'info' },
  {
    key: 'email-suppressions',
    labelKey: 'emailSuppressions',
    href: '/dashboard/comms/email-suppressions',
    icon: 'mail-x',
  },
  {
    key: 'webhook-logs',
    labelKey: 'webhookLogs',
    href: '/dashboard/comms/webhook-logs',
    icon: 'webhook',
  },
  { key: 'audit', href: '/dashboard/audit', icon: 'scroll-text' },
  { key: 'notifications', href: '/dashboard/notifications', icon: 'notification-bing' },
  { key: 'settings', href: '/dashboard/settings', icon: 'setting' },
];
