import { beforeEach, describe, expect, it, vi } from 'vitest';
import { screen } from '@testing-library/react';
import { ReportsList } from './reports-list';
import { renderWithProviders } from '@/test/render-with-providers';
import type { ReportRow } from '@/features/reports/types';

vi.mock('next/navigation', () => ({
  useRouter: () => ({
    push: vi.fn(),
    refresh: vi.fn(),
  }),
  useSearchParams: () => new URLSearchParams(),
  usePathname: () => '/dashboard/reports',
}));

const sampleReports: ReportRow[] = [
  {
    id: 'report-1',
    reportNumber: 'R-1001',
    name: 'Illegal dumping near park',
    location: 'Skopje',
    dateReportedAt: '2026-06-01T10:00:00.000Z',
    status: 'NEW',
    isPotentialDuplicate: false,
    coReporterCount: 0,
    cleanupEffortLabel: null,
  },
];

describe('ReportsList', () => {
  beforeEach(() => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({ data: [], meta: { total: 0, page: 1, limit: 20 } }),
      }),
    );
  });

  it('renders the reports queue header and table row', async () => {
    renderWithProviders(<ReportsList reports={sampleReports} />);

    expect(screen.getByRole('heading', { name: 'Reports' })).toBeInTheDocument();
    expect(screen.getAllByText('Illegal dumping near park').length).toBeGreaterThan(0);
    expect(
      screen.getByRole('textbox', { name: 'Search reports by name, location, or number' }),
    ).toBeInTheDocument();
  });
});
