import { ProfileMenuAction, TopBarCommand } from '../types/top-bar';

export const topBarCommands: ReadonlyArray<TopBarCommand> = [
  {
    id: 'go-dashboard',
    label: 'Go to Dashboard',
    description: 'Open admin overview metrics and report table',
    icon: 'home',
    keywords: ['overview', 'home', 'stats'],
    action: {
      type: 'navigate',
      href: '/dashboard',
    },
  },
  {
    id: 'go-reports',
    label: 'Go to Reports',
    description: 'Review incoming pollution reports',
    icon: 'document-text',
    keywords: ['moderation', 'review', 'incidents'],
    action: {
      type: 'navigate',
      href: '/dashboard/reports',
    },
  },
  {
    id: 'go-duplicates',
    label: 'Go to Duplicate Reports',
    description: 'Merge duplicate report groups',
    icon: 'document-forward',
    keywords: ['merge', 'duplicates', 'groups'],
    action: {
      type: 'navigate',
      href: '/dashboard/reports/duplicates',
    },
  },
  {
    id: 'go-users',
    label: 'Go to Users',
    description: 'Browse and manage admin users',
    icon: 'users',
    keywords: ['accounts', 'moderators', 'people'],
    action: {
      type: 'navigate',
      href: '/dashboard/users',
    },
  },
  {
    id: 'go-sites',
    label: 'Go to Sites',
    description: 'Pollution sites and lifecycle status',
    icon: 'location',
    keywords: ['places', 'locations', 'canonical'],
    action: {
      type: 'navigate',
      href: '/dashboard/sites',
    },
  },
  {
    id: 'go-map',
    label: 'Go to Map',
    description: 'Sites on the map',
    icon: 'map',
    keywords: ['geo', 'markers', 'clusters'],
    action: {
      type: 'navigate',
      href: '/dashboard/map',
    },
  },
  {
    id: 'go-events',
    label: 'Go to Cleanup Events',
    description: 'Schedule and review cleanup events',
    icon: 'calendar',
    keywords: ['cleanups', 'volunteers'],
    action: {
      type: 'navigate',
      href: '/dashboard/events',
    },
  },
  {
    id: 'go-audit',
    label: 'Go to Audit Log',
    description: 'Admin activity and changes',
    icon: 'scroll-text',
    keywords: ['history', 'compliance', 'trail'],
    action: {
      type: 'navigate',
      href: '/dashboard/audit',
    },
  },
  {
    id: 'go-settings',
    label: 'Go to Settings',
    description: 'Manage profile and admin preferences',
    icon: 'setting',
    keywords: ['profile', 'preferences'],
    action: {
      type: 'navigate',
      href: '/dashboard/settings',
    },
  },
  {
    id: 'open-notifications',
    label: 'Go to Notifications',
    description: 'Open the notifications activity center',
    icon: 'notification-bing',
    keywords: ['alerts', 'activity', 'updates'],
    action: {
      type: 'navigate',
      href: '/dashboard/notifications',
    },
  },
  {
    id: 'open-profile',
    label: 'Open Profile Menu',
    description: 'Quick access to account actions',
    icon: 'user',
    keywords: ['account', 'user'],
    action: {
      type: 'open-profile',
    },
  },
  {
    id: 'open-preferences',
    label: 'Open Preferences',
    description: 'Display and notification preferences',
    icon: 'setting',
    keywords: ['theme', 'controls', 'locale', 'motion'],
    action: {
      type: 'navigate',
      href: '/dashboard/settings?section=preferences',
    },
  },
  {
    id: 'sign-out',
    label: 'Sign out',
    description: 'Return to login screen',
    icon: 'log-out',
    keywords: ['logout', 'exit'],
    action: {
      type: 'sign-out',
    },
  },
];

export const profileMenuActions: ReadonlyArray<ProfileMenuAction> = [
  {
    id: 'profile-settings',
    label: 'Profile settings',
    icon: 'setting',
    action: 'go-to-settings',
  },
  {
    id: 'profile-preferences',
    label: 'Preferences',
    icon: 'user',
    action: 'open-preferences',
  },
  {
    id: 'profile-signout',
    label: 'Sign out',
    icon: 'log-out',
    action: 'sign-out',
  },
];
