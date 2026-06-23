import type { IconName } from '@/components/ui';
import type { AdminPermission } from '@/lib/auth/rbac/permissions';

export type CommandGroup =
  | 'recent'
  | 'navigation'
  | 'actions'
  | 'context'
  | 'users'
  | 'reports'
  | 'sites'
  | 'events';

export type CommandMessageNamespace = 'nav' | 'common' | 'commandPalette';

export type CommandAction =
  | { type: 'navigate'; href: string }
  | { type: 'open-profile' }
  | { type: 'open-notifications-panel' }
  | { type: 'sign-out' }
  | { type: 'refresh-page' }
  | { type: 'clear-recents' };

export type CommandDefinition = {
  id: string;
  group: CommandGroup;
  labelKey: string;
  descriptionKey?: string;
  messageNamespace?: CommandMessageNamespace;
  icon: IconName;
  keywords?: readonly string[];
  permission?: AdminPermission;
  href?: string;
  action: CommandAction;
  scoreBoost?: number;
};

export type ResolvedCommand = CommandDefinition & {
  label: string;
  description?: string;
  searchKeywords: string[];
};

export type ScoredCommand = {
  command: ResolvedCommand;
  score: number;
  labelMatch?: { start: number; end: number };
};

export const COMMAND_GROUP_ORDER: readonly CommandGroup[] = [
  'recent',
  'navigation',
  'context',
  'actions',
  'users',
  'reports',
  'sites',
  'events',
];
