import { ProfileMenuAction } from '../types/top-bar';

export const profileMenuActions: ReadonlyArray<ProfileMenuAction> = [
  {
    id: 'profile-settings',
    labelKey: 'profileSettings',
    icon: 'setting',
    action: 'go-to-settings',
  },
  {
    id: 'profile-preferences',
    labelKey: 'preferences',
    icon: 'user',
    action: 'open-preferences',
  },
  {
    id: 'profile-signout',
    labelKey: 'signOut',
    icon: 'log-out',
    action: 'sign-out',
  },
];
