import type { IconName } from '@/components/ui';

export type AdminSession = {
  id: string;
  device: string;
  location: string;
  ipAddress: string;
  lastActiveLabel: string;
  isCurrent: boolean;
};

export type SecurityActivityTone = 'success' | 'warning' | 'info';

export type SecurityActivityEvent = {
  id: string;
  title: string;
  detail: string;
  occurredAtLabel: string;
  tone: SecurityActivityTone;
  icon: IconName;
};

export const mockAdminSessions: AdminSession[] = [
  {
    id: 'session-current',
    device: 'Safari on macOS',
    location: 'Skopje, North Macedonia',
    ipAddress: '192.168.0.24',
    lastActiveLabel: 'Just now',
    isCurrent: true,
  },
  {
    id: 'session-iphone',
    device: 'Safari on iPhone',
    location: 'Skopje, North Macedonia',
    ipAddress: '10.0.0.18',
    lastActiveLabel: '2 hours ago',
    isCurrent: false,
  },
  {
    id: 'session-work-laptop',
    device: 'Chrome on work laptop',
    location: 'Berlin, Germany',
    ipAddress: '83.144.12.98',
    lastActiveLabel: 'Yesterday · 21:18',
    isCurrent: false,
  },
];

export const mockSecurityActivity: SecurityActivityEvent[] = [
  {
    id: 'activity-password-changed',
    title: 'Password changed',
    detail: 'You updated your password from this device.',
    occurredAtLabel: 'Today · 14:21',
    tone: 'success',
    icon: 'check',
  },
  {
    id: 'activity-new-login-mac',
    title: 'New sign-in · Safari on macOS',
    detail: 'Successful login from Skopje, North Macedonia.',
    occurredAtLabel: 'Today · 09:03',
    tone: 'info',
    icon: 'user',
  },
  {
    id: 'activity-session-signed-out',
    title: 'Signed out of other sessions',
    detail: 'You signed out of sessions on other devices.',
    occurredAtLabel: 'Yesterday · 20:02',
    tone: 'info',
    icon: 'log-out',
  },
  {
    id: 'activity-unusual-location',
    title: 'Unusual sign-in attempt blocked',
    detail: 'We blocked a login from an unrecognised location.',
    occurredAtLabel: '2 days ago · 07:14',
    tone: 'warning',
    icon: 'location',
  },
];

