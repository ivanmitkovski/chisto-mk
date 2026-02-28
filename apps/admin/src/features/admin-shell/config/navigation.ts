import { NavItem } from '../types';

export const adminNavigation: ReadonlyArray<NavItem> = [
  { key: 'dashboard', label: 'Dashboard', href: '/dashboard', icon: 'home' },
  { key: 'reports', label: 'Reports', href: '/dashboard/reports', icon: 'document-text' },
  { key: 'duplicates', label: 'Duplicates', href: '/dashboard/reports/duplicates', icon: 'document-forward' },
  { key: 'settings', label: 'Settings', href: '/dashboard/settings', icon: 'setting' },
];
