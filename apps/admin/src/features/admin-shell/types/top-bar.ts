import type { IconName } from '@/components/ui';
import type { ResolvedCommand } from '../commands/types';

export type TopBarCommandAction = ResolvedCommand['action'];

export type TopBarCommand = ResolvedCommand;

export type TopBarNotification = {
  id: string;
  title: string;
  message: string;
  timeLabel: string;
  /** ISO 8601 from API — preferred source for relative time in the UI */
  createdAt?: string;
  isUnread: boolean;
  href?: string;
};

export type ProfileMenuAction = {
  id: string;
  labelKey: 'profileSettings' | 'preferences' | 'signOut';
  icon: IconName;
  action: 'go-to-settings' | 'open-preferences' | 'sign-out';
};
