import { NavItem } from '../types';

export const adminNavigation: ReadonlyArray<NavItem> = [
  { key: 'dashboard', label: 'Dashboard', href: '/dashboard', icon: 'home' },
  { key: 'reports', label: 'Reports', href: '/dashboard/reports', icon: 'document-text' },
  { key: 'settings', label: 'Settings', href: '/dashboard/settings', icon: 'setting' },
];
