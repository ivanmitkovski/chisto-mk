import { IconName } from '@/components/ui';
import type { AdminPermission } from '@/lib/auth/rbac/permissions';

export type TopBarCommandAction =
  | {
      type: 'navigate';
      href: string;
    }
  | {
      type: 'open-profile';
    }
  | {
      type: 'sign-out';
    };

export type TopBarCommandDefinition = {
  id: string;
  labelKey: string;
  descriptionKey?: string;
  /** Defaults to `nav`. Use `common` for global command palette entries. */
  messageNamespace?: 'nav' | 'common';
  icon: IconName;
  keywords: readonly string[];
  /** When set, command is hidden unless the user has this permission. */
  permission?: AdminPermission;
  action: TopBarCommandAction;
};

export type TopBarCommand = TopBarCommandDefinition & {
  label: string;
  description?: string;
};

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
