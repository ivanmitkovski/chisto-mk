import { NavItem } from '../types';

export const adminNavigation: ReadonlyArray<NavItem> = [
  { key: 'dashboard', label: 'Dashboard', href: '/dashboard', icon: 'home' },
  { key: 'reports', label: 'Reports', href: '/dashboard/reports', icon: 'document-text' },
  { key: 'duplicates', label: 'Duplicates', href: '/dashboard/reports/duplicates', icon: 'document-forward' },
  { key: 'users', label: 'Users', href: '/dashboard/users', icon: 'users' },
  { key: 'sites', label: 'Sites', href: '/dashboard/sites', icon: 'location' },
  { key: 'map', label: 'Map', href: '/dashboard/map', icon: 'map' },
  { key: 'events', label: 'Events', href: '/dashboard/events', icon: 'calendar' },
  { key: 'audit', label: 'Audit', href: '/dashboard/audit', icon: 'scroll-text' },
  { key: 'notifications', label: 'Notifications', href: '/dashboard/notifications', icon: 'notification-bing' },
  { key: 'settings', label: 'Settings', href: '/dashboard/settings', icon: 'setting' },
];
