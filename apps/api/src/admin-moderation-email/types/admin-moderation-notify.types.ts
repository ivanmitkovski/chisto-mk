import { AdminModerationCategory } from '../../prisma-client';

export type AdminModerationNotifyParams = {
  category: AdminModerationCategory;
  resourceId: string;
  deepLinkPath: string;
  emailContext: Record<string, unknown>;
};
