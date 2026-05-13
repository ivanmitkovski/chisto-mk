import { CleanupEventStatus, EcoEventCategory, EcoEventLifecycleStatus } from '../../src/prisma-client';

type CleanupEventRow = {
  id: string;
  siteId: string;
  title: string;
  description: string;
  category: EcoEventCategory;
  scheduledAt: Date;
  status: CleanupEventStatus;
  lifecycleStatus: EcoEventLifecycleStatus;
  organizerId: string;
  participantCount: number;
  createdAt: Date;
  updatedAt: Date;
};

export function buildCleanupEventRow(overrides: Partial<CleanupEventRow> = {}): CleanupEventRow {
  const id = overrides.id ?? 'evt_row_1';
  const now = overrides.createdAt ?? new Date('2026-03-01T10:00:00.000Z');
  return {
    id,
    siteId: overrides.siteId ?? 'site_row_1',
    title: overrides.title ?? 'River cleanup',
    description: overrides.description ?? 'Join us',
    category: overrides.category ?? EcoEventCategory.RIVER_AND_LAKE,
    scheduledAt: overrides.scheduledAt ?? new Date('2026-06-01T09:00:00.000Z'),
    status: overrides.status ?? CleanupEventStatus.APPROVED,
    lifecycleStatus: overrides.lifecycleStatus ?? EcoEventLifecycleStatus.UPCOMING,
    organizerId: overrides.organizerId ?? 'user_row_1',
    participantCount: overrides.participantCount ?? 0,
    createdAt: overrides.createdAt ?? now,
    updatedAt: overrides.updatedAt ?? now,
  };
}
