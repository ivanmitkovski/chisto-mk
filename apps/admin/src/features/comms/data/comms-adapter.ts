import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';
import type { CommsListMeta, EmailSuppressionRow, WebhookLogRow } from '../types';

type EmailSuppressionsResponse = {
  data: EmailSuppressionRow[];
  meta: CommsListMeta;
};

type WebhookLogsResponse = {
  data: WebhookLogRow[];
  meta: CommsListMeta;
};

export async function getEmailSuppressions(params?: {
  page?: number;
  limit?: number;
  search?: string;
  reason?: string;
  source?: string;
}): Promise<EmailSuppressionsResponse> {
  const page = params?.page ?? 1;
  const limit = params?.limit ?? 50;
  const search = new URLSearchParams({
    page: String(page),
    limit: String(limit),
  });
  if (params?.search?.trim()) {
    search.set('search', params.search.trim());
  }
  if (params?.reason?.trim()) {
    search.set('reason', params.reason.trim());
  }
  if (params?.source?.trim()) {
    search.set('source', params.source.trim());
  }
  return serverAuthenticatedFetch<EmailSuppressionsResponse>(`/admin/comms/email-suppressions?${search.toString()}`, {
    method: 'GET',
  });
}

export async function getWebhookLogs(params?: {
  page?: number;
  limit?: number;
  action?: string;
}): Promise<WebhookLogsResponse> {
  const page = params?.page ?? 1;
  const limit = params?.limit ?? 50;
  const search = new URLSearchParams({
    page: String(page),
    limit: String(limit),
  });
  if (params?.action?.trim()) {
    search.set('action', params.action.trim());
  }
  return serverAuthenticatedFetch<WebhookLogsResponse>(`/admin/comms/webhook-logs?${search.toString()}`, {
    method: 'GET',
  });
}
