export type BroadcastCampaignStatus = 'draft' | 'scheduled' | 'sent' | 'cancelled';

export type BroadcastCampaign = {
  id: string;
  title: string;
  body: string;
  type: string;
  deeplink?: string | undefined;
  audience: 'all' | 'active' | 'area' | 'users';
  audienceUserIds?: string[] | undefined;
  status: BroadcastCampaignStatus;
  scheduledAt?: string | undefined;
  sentAt?: string | undefined;
  sentCount?: number | undefined;
  createdAt: string;
  updatedAt: string;
};

export type CreateBroadcastInput = {
  title: string;
  body: string;
  type: string;
  deeplink?: string | undefined;
  audience: BroadcastCampaign['audience'];
  audienceUserIds?: string[] | undefined;
  scheduledAt?: string | undefined;
  createdById?: string | undefined;
};

export type UpdateBroadcastInput = {
  title?: string | undefined;
  body?: string | undefined;
  type?: string | undefined;
  deeplink?: string | undefined;
  audience?: BroadcastCampaign['audience'] | undefined;
  audienceUserIds?: string[] | undefined;
  scheduledAt?: string | null | undefined;
};
