import { SiteResolutionStatus } from '../../../prisma-client';

export const ALLOWED_SITE_RESOLUTION_STATUS_TRANSITIONS: Record<
  SiteResolutionStatus,
  SiteResolutionStatus[]
> = {
  PENDING: ['APPROVED', 'REJECTED'],
  APPROVED: ['REJECTED'],
  REJECTED: [],
};
