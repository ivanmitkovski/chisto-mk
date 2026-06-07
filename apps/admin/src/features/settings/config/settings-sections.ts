import type { IconName } from '@/components/ui';

export type SectionId =
  | 'profile'
  | 'security'
  | 'environment'
  | 'featureFlags'
  | 'moderationEmails'
  | 'preferences';

export const SECTION_IDS: SectionId[] = [
  'profile',
  'security',
  'environment',
  'featureFlags',
  'moderationEmails',
  'preferences',
];

export type SectionGroupConfig = {
  labelKey: 'groups.account' | 'groups.system' | 'groups.preferences';
  items: { id: SectionId; labelKey: `sections.${SectionId}`; icon: IconName }[];
};

export const SIDEBAR_GROUPS: SectionGroupConfig[] = [
  {
    labelKey: 'groups.account',
    items: [
      { id: 'profile', labelKey: 'sections.profile', icon: 'user' },
      { id: 'security', labelKey: 'sections.security', icon: 'shield' },
    ],
  },
  {
    labelKey: 'groups.system',
    items: [
      { id: 'environment', labelKey: 'sections.environment', icon: 'setting' },
      { id: 'featureFlags', labelKey: 'sections.featureFlags', icon: 'document-duplicate' },
    ],
  },
  {
    labelKey: 'groups.preferences',
    items: [
      { id: 'moderationEmails', labelKey: 'sections.moderationEmails', icon: 'mail-x' },
      { id: 'preferences', labelKey: 'sections.preferences', icon: 'document-text' },
    ],
  },
];
