/**
 * @vitest-environment jsdom
 */
import { describe, expect, it, afterEach, vi } from 'vitest';
import type { ReactElement } from 'react';
import { cleanup, screen } from '@testing-library/react';
import { OperationsDeadLettersPanel } from './operations-dead-letters-panel';
import { renderWithProviders } from '@/test/render-with-providers';
import enOperations from '@/i18n/messages/en/operations.json';
import { NextIntlClientProvider } from 'next-intl';

vi.mock('./operations-live-provider', () => ({
  useOperationsLive: () => ({ refresh: vi.fn(), isRefreshing: false, getSeries: () => [] }),
}));

function renderPanel(ui: ReactElement) {
  return renderWithProviders(
    <NextIntlClientProvider locale="en" messages={{ operations: enOperations }}>
      {ui}
    </NextIntlClientProvider>,
  );
}

const row = {
  id: 'dl-1',
  userNotificationId: 'notif-1',
  deviceTokenSuffix: 'abcd',
  attempts: 3,
  lastErrorCode: 'messaging/third-party-auth-error',
  lastErrorMessage: 'Auth error',
  lastAttemptAt: '2026-06-01T10:00:00.000Z',
  createdAt: '2026-06-01T09:00:00.000Z',
};

describe('OperationsDeadLettersPanel', () => {
  afterEach(() => {
    cleanup();
  });

  it('syncs rows when snapshot props change after refresh', () => {
    const { rerender } = renderPanel(
      <OperationsDeadLettersPanel
        initialData={[]}
        initialMeta={{ page: 1, limit: 10, total: 0 }}
        snapshotUpdatedAt="2026-06-01T10:00:00.000Z"
      />,
    );

    expect(screen.getByText(/No push dead letters/i)).toBeInTheDocument();

    rerender(
      <NextIntlClientProvider locale="en" messages={{ operations: enOperations }}>
        <OperationsDeadLettersPanel
          initialData={[row]}
          initialMeta={{ page: 1, limit: 10, total: 1 }}
          snapshotUpdatedAt="2026-06-01T10:01:00.000Z"
        />
      </NextIntlClientProvider>,
    );

    expect(screen.getByText(/third-party-auth-error/i)).toBeInTheDocument();
  });
});
