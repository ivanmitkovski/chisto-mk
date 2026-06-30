import type { ReactElement } from 'react';
import { describe, expect, it, vi } from 'vitest';
import { screen } from '@testing-library/react';
import { NextIntlClientProvider } from 'next-intl';
import { render } from '@testing-library/react';
import { ToastProvider } from '@/components/ui';
import { UserModerationActionRail } from './user-moderation-action-rail';
import enUsers from '@/i18n/messages/en/users.json';

vi.mock('next/navigation', () => ({
  useRouter: () => ({ refresh: vi.fn() }),
}));

function renderRail(ui: ReactElement) {
  return render(
    <NextIntlClientProvider locale="en" messages={{ users: enUsers }}>
      <ToastProvider>{ui}</ToastProvider>
    </NextIntlClientProvider>,
  );
}

describe('UserModerationActionRail', () => {
  it('renders suspend for active users with write access', () => {
    const actionButtonsRef = { current: [] as Array<HTMLButtonElement | null> };
    renderRail(
      <UserModerationActionRail
        userId="user-1"
        status="ACTIVE"
        profileDirty={false}
        canViewSessions
        actionButtonsRef={actionButtonsRef}
        onActionRailKeyDown={() => undefined}
      />,
    );

    expect(screen.getByRole('button', { name: /suspend/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /revoke all sessions/i })).toBeInTheDocument();
  });

  it('blocks actions when profile is dirty', () => {
    const actionButtonsRef = { current: [] as Array<HTMLButtonElement | null> };
    renderRail(
      <UserModerationActionRail
        userId="user-1"
        status="ACTIVE"
        profileDirty
        canViewSessions
        actionButtonsRef={actionButtonsRef}
        onActionRailKeyDown={() => undefined}
      />,
    );

    expect(screen.getByRole('status')).toHaveTextContent(/save or discard/i);
    expect(actionButtonsRef.current[0]?.disabled).toBe(true);
  });
});
