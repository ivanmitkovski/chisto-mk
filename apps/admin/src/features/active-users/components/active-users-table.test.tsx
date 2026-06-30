import { describe, expect, it, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import { NextIntlClientProvider } from 'next-intl';
import { ActiveUsersTable } from './active-users-table';
import type { ActiveUserRow } from '../data/active-users.types';

vi.mock('../hooks/use-active-users-live', () => ({
  useActiveUsersLive: () => ({
    rows: [
      {
        id: 'user-1:dev-1',
        userId: 'user-1',
        deviceId: 'dev-1',
        firstName: 'Ada',
        lastName: 'Lovelace',
        email: 'ada@example.com',
        avatarUrl: null,
        status: 'online',
        currentScreen: 'Feed',
        platform: 'IOS',
        appVersion: '1.0.0',
        lastActivity: '2026-06-08T10:00:00.000Z',
        sessionDurationSeconds: 120,
        deviceModel: 'iPhone',
        country: 'MK',
        city: 'Skopje',
        role: 'USER',
      } satisfies ActiveUserRow,
    ],
    listTotal: 1,
    listError: null,
    refresh: vi.fn(),
  }),
}));

const messages = {
  ui: { noData: 'No data' },
  activeUsers: {
    user: 'User',
    statusLabel: 'Status',
    screen: 'Screen',
    platformLabel: 'Platform',
    deviceModel: 'Device',
    location: 'Location',
    sessionDuration: 'Session',
    lastActivity: 'Last activity',
    status: { online: 'Online', away: 'Away', offline: 'Offline' },
  },
};

describe('ActiveUsersTable', () => {
  it('renders user link and status pill', () => {
    render(
      <NextIntlClientProvider locale="en" messages={messages}>
        <ActiveUsersTable page={1} onPageChange={() => {}} />
      </NextIntlClientProvider>,
    );

    expect(screen.getAllByRole('link', { name: 'Ada Lovelace' })[0]).toHaveAttribute(
      'href',
      '/dashboard/users/user-1?tab=activity',
    );
    expect(screen.getAllByText('Online').length).toBeGreaterThan(0);
    expect(screen.getAllByText('Feed').length).toBeGreaterThan(0);
  });
});
