import type { ReactElement } from 'react';
import { describe, expect, it, vi } from 'vitest';
import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { NextIntlClientProvider } from 'next-intl';
import { render } from '@testing-library/react';
import { EventDetailModerationActionRail } from './event-detail-moderation-action-rail';
import enEvents from '@/i18n/messages/en/events.json';

function renderRail(ui: ReactElement) {
  return render(
    <NextIntlClientProvider locale="en" messages={{ events: enEvents }}>
      {ui}
    </NextIntlClientProvider>,
  );
}

const baseEvent = {
  id: 'evt-1',
  title: 'Park cleanup',
  description: 'Help clean the park',
  siteId: 'site-1',
  scheduledAt: '2025-07-01T10:00:00.000Z',
  completedAt: null,
  organizerId: null,
  participantCount: 2,
  status: 'PENDING' as const,
  lifecycleStatus: 'UPCOMING' as const,
  recurrenceRule: null,
  site: {
    id: 'site-1',
    latitude: 41.99,
    longitude: 21.43,
    description: null,
    status: 'ACTIVE',
  },
};

describe('EventDetailModerationActionRail', () => {
  it('renders approve and decline for pending writable events', () => {
    const actionButtonsRef = { current: [] as Array<HTMLButtonElement | null> };
    renderRail(
      <EventDetailModerationActionRail
        event={baseEvent}
        canWriteCleanupEvents
        saving={false}
        isDirty={false}
        actionButtonsRef={actionButtonsRef}
        onActionRailKeyDown={() => undefined}
        onApprove={() => undefined}
        onDecline={() => undefined}
        onReturnToPending={() => undefined}
        returnToPendingOpen={false}
        onReturnToPendingConfirm={() => undefined}
        onReturnToPendingClose={() => undefined}
      />,
    );

    expect(screen.getByRole('button', { name: /approve/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /decline/i })).toBeInTheDocument();
  });

  it('shows return to pending for approved events', async () => {
    const user = userEvent.setup();
    const onReturnToPending = vi.fn();
    const actionButtonsRef = { current: [] as Array<HTMLButtonElement | null> };

    renderRail(
      <EventDetailModerationActionRail
        event={{ ...baseEvent, status: 'APPROVED' }}
        canWriteCleanupEvents
        saving={false}
        isDirty={false}
        actionButtonsRef={actionButtonsRef}
        onActionRailKeyDown={() => undefined}
        onApprove={() => undefined}
        onDecline={() => undefined}
        onReturnToPending={onReturnToPending}
        returnToPendingOpen={false}
        onReturnToPendingConfirm={() => undefined}
        onReturnToPendingClose={() => undefined}
      />,
    );

    await user.click(screen.getByRole('button', { name: /return to pending/i }));
    expect(onReturnToPending).toHaveBeenCalled();
  });
});
