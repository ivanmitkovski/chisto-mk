import { describe, expect, it, vi, afterEach } from 'vitest';
import { cleanup, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ReportModeratorAssignPicker } from './report-moderator-assign-picker';
import { renderWithProviders } from '@/test/render-with-providers';
import type { EligibleModerator } from '../data/eligible-moderators';
import type { ReportDetail } from '../types';

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

function createAssignMock() {
  return {
    assignToMe: vi.fn(),
    assignToModerator: vi.fn().mockResolvedValue(undefined),
    releaseAssignment: vi.fn().mockResolvedValue(undefined),
    isAssigning: false,
    isAssignedToMe: false,
    hasAssignee: false,
  };
}

describe('ReportModeratorAssignPicker', () => {
  afterEach(() => {
    cleanup();
  });

  it('renders the moderator combobox with staff options', () => {
    renderWithProviders(
      <ReportModeratorAssignPicker
        report={report}
        eligibleModerators={eligibleModerators}
        assign={createAssignMock()}
      />,
    );

    expect(screen.getByLabelText('Assign moderator')).toBeInTheDocument();
    expect(screen.getByRole('combobox')).toBeInTheDocument();
  });

  it('opens confirm dialog when selecting a moderator', async () => {
    const user = userEvent.setup();

    renderWithProviders(
      <ReportModeratorAssignPicker
        report={report}
        eligibleModerators={eligibleModerators}
        assign={createAssignMock()}
      />,
    );

    const combobox = screen.getByLabelText('Assign moderator');
    await user.click(combobox);
    await user.click(screen.getByRole('option', { name: /Grace Hopper · Admin/i }));

    expect(await screen.findByRole('dialog')).toBeInTheDocument();
    expect(screen.getByText('Assign this report to Grace Hopper?')).toBeInTheDocument();
  });

  it('assigns moderator after confirmation', async () => {
    const user = userEvent.setup();
    const assign = createAssignMock();

    renderWithProviders(
      <ReportModeratorAssignPicker
        report={report}
        eligibleModerators={eligibleModerators}
        assign={assign}
      />,
    );

    const combobox = screen.getByLabelText('Assign moderator');
    await user.click(combobox);
    await user.click(screen.getByRole('option', { name: /Grace Hopper · Admin/i }));
    await user.click(screen.getByRole('button', { name: 'Confirm' }));

    await waitFor(() => {
      expect(assign.assignToModerator).toHaveBeenCalledWith('mod-2', 'Grace Hopper');
    });
  });
});
