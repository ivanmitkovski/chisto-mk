export type SiteEventType = 'site_created' | 'site_updated';

export type SiteEvent = {
  eventId: string;
  type: SiteEventType;
  siteId: string;
  occurredAtMs: number;
  updatedAt: string;
  mutation: {
    kind: 'created' | 'updated' | 'status_changed';
    status?: string;
    latitude?: number;
    longitude?: number;
  };
};
