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
    description: 'Preferences controls are planned next',
    icon: 'setting',
    keywords: ['theme', 'controls', 'soon'],
    action: {
      type: 'preferences-placeholder',
    },
  },
  {
    id: 'sign-out',
    label: 'Sign out',
    description: 'Return to login screen',
    icon: 'log-out',
    keywords: ['logout', 'exit'],
    action: {
      type: 'navigate',
      href: '/login',
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
