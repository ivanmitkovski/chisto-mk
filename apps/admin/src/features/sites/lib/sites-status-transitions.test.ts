import { describe, expect, it } from 'vitest';
import {
  countSitesEligibleForBulkStatus,
  isAllowedSiteStatusTransition,
} from './sites-status-transitions';

describe('sites status transitions', () => {
  it('allows valid single-step transitions', () => {
    expect(isAllowedSiteStatusTransition('REPORTED', 'VERIFIED')).toBe(true);
    expect(isAllowedSiteStatusTransition('VERIFIED', 'CLEANUP_SCHEDULED')).toBe(true);
    expect(isAllowedSiteStatusTransition('IN_PROGRESS', 'CLEANED')).toBe(true);
  });

  it('rejects invalid transitions', () => {
    expect(isAllowedSiteStatusTransition('REPORTED', 'CLEANED')).toBe(false);
    expect(isAllowedSiteStatusTransition('CLEANED', 'VERIFIED')).toBe(false);
  });

  it('counts only sites eligible for a bulk target status', () => {
    const sites = [
      { status: 'REPORTED' },
      { status: 'VERIFIED' },
      { status: 'IN_PROGRESS' },
    ];

    expect(countSitesEligibleForBulkStatus(sites, 'VERIFIED')).toBe(1);
    expect(countSitesEligibleForBulkStatus(sites, 'CLEANED')).toBe(1);
    expect(countSitesEligibleForBulkStatus(sites, 'DISPUTED')).toBe(3);
  });
});
