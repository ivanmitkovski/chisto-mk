import { render, screen } from '@testing-library/react';
import { SiteTimelinePanel } from '@/features/sites/components/site-timeline-panel';

jest.mock('@/lib/api/site-history', () => ({
  fetchSiteHistory: jest.fn().mockResolvedValue({
    items: [
      {
        id: 'h1',
        kind: 'SITE_CREATED',
        occurredAt: '2026-05-01T12:00:00.000Z',
        fromStatus: null,
        toStatus: 'REPORTED',
        reportId: null,
        cleanupEventId: null,
        actor: null,
        note: null,
        metadata: null,
      },
    ],
    nextBeforeId: null,
  }),
}));

describe('SiteTimelinePanel', () => {
  it('renders timeline entries after load', async () => {
    render(<SiteTimelinePanel siteId="site-1" />);
    expect(await screen.findByText(/Site Created/i)).toBeInTheDocument();
    expect(screen.getByText(/1 events/i)).toBeInTheDocument();
  });
});
