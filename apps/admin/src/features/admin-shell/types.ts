import { IconName } from '@/components/ui';

export type NavItemKey = 'dashboard' | 'reports' | 'duplicates' | 'settings';

export type NavItem = {
  key: NavItemKey;
  label: string;
  href: string;
  icon: IconName;
};
