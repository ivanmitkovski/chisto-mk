import { afterEach, describe, expect, it, vi } from 'vitest';
import { cleanup, screen } from '@testing-library/react';
import { ReportReviewOperationalContext } from './report-review-card/report-review-operational-context';
import { renderWithProviders } from '@/test/render-with-providers';
import { PermissionsProvider } from '@/lib/auth/rbac';
import type { EligibleModerator } from '../data/eligible-moderators';
import type { ReportDetail } from '../types';

const assignMock = {
  assignToMe: vi.fn(),
  assignToModerator: vi.fn(),
  releaseAssignment: vi.fn(),
  isAssigning: false,
  isAssignedToMe: false,
  hasAssignee: false,
};

vi.mock('../hooks/use-report-assign', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../hooks/use-report-assign')>();
  return {
    ...actual,
    useReportAssign: () => assignMock,
  };
});

const eligibleModerators: EligibleModerator[] = [
  {
    id: 'mod-2',
    firstName: 'Grace',
    lastName: 'Hopper',
    email: 'grace@example.com',
    role: 'ADMIN',
  },
];

const report: ReportDetail = {
  id: 'report-1',
  reportNumber: 'CH-000001',
  status: 'IN_REVIEW',
  priority: 'LOW',
  title: 'Sample report',
  description: 'Details',
  location: 'Skopje',
  submittedAt: '2026-06-01T10:00:00.000Z',
  reporterAlias: 'Reporter',
  reporterTrust: 'Bronze',
  evidence: [],
  timeline: [],
  moderation: {
    queueLabel: 'General Queue',
    slaLabel: '1h remaining',
    assignedTeam: 'General Queue',
    assignedModeratorId: null,
    assignedModeratorName: null,
  },
  mapPin: { latitude: 41.99, longitude: 21.43, label: 'Skopje' },
  isPotentialDuplicate: false,
  coReporters: [],
  cleanupEffortLabel: null,
};

describe('ReportReviewOperationalContext assignment picker', () => {
  afterEach(() => {
    cleanup();
  });

  it('shows admin assign picker for admin viewers', () => {
    renderWithProviders(
      <PermissionsProvider role="ADMIN">
        <ReportReviewOperationalContext
          report={report}
          viewerRole="ADMIN"
          eligibleModerators={eligibleModerators}
        />
      </PermissionsProvider>,
    );

    expect(screen.getByLabelText('Assign moderator')).toBeInTheDocument();
  });

  it('does not show admin assign picker for support viewers', () => {
    renderWithProviders(
      <PermissionsProvider role="SUPPORT">
        <ReportReviewOperationalContext
          report={report}
          viewerRole="SUPPORT"
          eligibleModerators={eligibleModerators}
        />
      </PermissionsProvider>,
    );

    expect(screen.queryByLabelText('Assign moderator')).not.toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Assign to me' })).toBeInTheDocument();
  });
});
