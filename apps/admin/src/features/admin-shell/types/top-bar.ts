import { IconName } from '@/components/ui';

export type TopBarCommandAction =
  | {
      type: 'navigate';
      href: string;
    }
  | {
      type: 'open-profile';
    }
  | {
      type: 'preferences-placeholder';
    };

export type TopBarCommand = {
  id: string;
  label: string;
  description?: string | undefined;
  icon: IconName;
  keywords: readonly string[];
  action: TopBarCommandAction;
};

export type TopBarNotification = {
  id: string;
  title: string;
  message: string;
  timeLabel: string;
  isUnread: boolean;
};

export type ProfileMenuAction = {
  id: string;
  label: string;
  icon: IconName;
  action: 'go-to-settings' | 'open-preferences' | 'sign-out';
};
