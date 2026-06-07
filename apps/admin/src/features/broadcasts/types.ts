export type BroadcastAudience = 'all' | 'active' | 'users';

export type BroadcastCampaignStatus = 'draft' | 'scheduled' | 'sent' | 'cancelled';

export type BroadcastCampaign = {
  id: string;
  title: string;
  body: string;
  type?: string;
  deeplink?: string;
  audience: BroadcastAudience | string;
  audienceUserIds?: string[];
  status: BroadcastCampaignStatus | string;
  scheduledAt?: string;
  sentAt?: string;
  sentCount?: number;
  createdAt?: string;
  updatedAt?: string;
};

export type BroadcastDeliveryReport = {
  sentCount: number;
  failedCount?: number;
};

export type BroadcastCampaignFormValues = {
  title: string;
  body: string;
  audience: BroadcastAudience;
  audienceUserIds: string;
  deeplink: string;
  /** datetime-local value (YYYY-MM-DDTHH:mm) or empty for immediate draft */
  scheduledAt: string;
};

export type BroadcastFormMode = 'create' | 'edit';
