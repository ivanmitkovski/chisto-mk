export type EmailSuppressionRow = {
  email: string;
  reason: string;
  source: string;
  createdAt: string;
  updatedAt: string;
};

export type WebhookLogRow = {
  id: string;
  action: string;
  resourceType: string | null;
  resourceId: string | null;
  actorId: string | null;
  createdAt: string;
  metadata: Record<string, unknown> | null;
};

export type CommsListMeta = {
  page: number;
  limit: number;
  total: number;
};
