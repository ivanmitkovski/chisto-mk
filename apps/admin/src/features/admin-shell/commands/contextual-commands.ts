import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import type { CommandDefinition } from './types';

export function getContextualCommands(pathname: string): CommandDefinition[] {
  const commands: CommandDefinition[] = [];

  if (pathname.startsWith('/dashboard/reports')) {
    commands.push({
      id: 'context-reports-in-review',
      group: 'context',
      labelKey: 'reportsInReview',
      descriptionKey: 'reportsInReviewDescription',
      messageNamespace: 'commandPalette',
      icon: 'document-forward',
      keywords: ['queue', 'moderation', 'pending'],
      permission: ADMIN_PERMISSIONS['reports:read'],
      href: '/dashboard/reports?status=IN_REVIEW',
      action: { type: 'navigate', href: '/dashboard/reports?status=IN_REVIEW' },
    });
  }

  if (pathname.startsWith('/dashboard/users')) {
    commands.push({
      id: 'context-users-suspended',
      group: 'context',
      labelKey: 'suspendedUsers',
      descriptionKey: 'suspendedUsersDescription',
      messageNamespace: 'commandPalette',
      icon: 'users',
      keywords: ['banned', 'disabled'],
      permission: ADMIN_PERMISSIONS['users:read'],
      href: '/dashboard/users?status=SUSPENDED',
      action: { type: 'navigate', href: '/dashboard/users?status=SUSPENDED' },
    });
  }

  if (pathname.startsWith('/dashboard/events')) {
    commands.push({
      id: 'context-events-pending-moderation',
      group: 'context',
      labelKey: 'eventsPendingModeration',
      descriptionKey: 'eventsPendingModerationDescription',
      messageNamespace: 'commandPalette',
      icon: 'calendar',
      keywords: ['approval', 'queue'],
      permission: ADMIN_PERMISSIONS['events:read'],
      href: '/dashboard/events?moderationStatus=PENDING',
      action: { type: 'navigate', href: '/dashboard/events?moderationStatus=PENDING' },
    });
  }

  if (pathname.startsWith('/dashboard/notifications')) {
    commands.push({
      id: 'context-notifications-unread',
      group: 'context',
      labelKey: 'unreadNotifications',
      descriptionKey: 'unreadNotificationsDescription',
      messageNamespace: 'commandPalette',
      icon: 'notification-bing',
      keywords: ['filter', 'unread'],
      permission: ADMIN_PERMISSIONS['notifications:read'],
      href: '/dashboard/notifications?onlyUnread=true',
      action: { type: 'navigate', href: '/dashboard/notifications?onlyUnread=true' },
    });
  }

  return commands;
}
