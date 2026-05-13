import { SiteStatus } from '../../src/prisma-client';

type SiteRow = {
  id: string;
  createdAt: Date;
  updatedAt: Date;
  latitude: number;
  longitude: number;
  description: string | null;
  status: SiteStatus;
  reportedById: string;
};

export function buildSiteRow(overrides: Partial<SiteRow> = {}): SiteRow {
  const id = overrides.id ?? 'site_row_1';
  const now = overrides.createdAt ?? new Date('2026-01-02T00:00:00.000Z');
  return {
    id,
    createdAt: overrides.createdAt ?? now,
    updatedAt: overrides.updatedAt ?? now,
    latitude: overrides.latitude ?? 41.9981,
    longitude: overrides.longitude ?? 21.4254,
    description: overrides.description ?? 'Test pollution site',
    status: overrides.status ?? SiteStatus.VERIFIED,
    reportedById: overrides.reportedById ?? 'user_row_1',
  };
}
