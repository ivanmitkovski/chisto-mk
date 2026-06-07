import { beforeEach, describe, expect, it, vi } from 'vitest';
import { cleanup, fireEvent, screen, waitFor } from '@testing-library/react';
import { NextIntlClientProvider } from 'next-intl';
import type { ReactNode } from 'react';
import { AcceptInviteFlow } from './accept-invite-flow';
import { MfaReminderBanner } from '@/features/admin-shell/components/mfa-reminder-banner';
import { renderWithProviders } from '@/test/render-with-providers';

import enAcceptInvite from '@/i18n/messages/en/acceptInvite.json';
import enCommon from '@/i18n/messages/en/common.json';
import enSettings from '@/i18n/messages/en/settings.json';

const replaceMock = vi.fn();
const pushMock = vi.fn();

vi.mock('next/navigation', () => ({
  useRouter: () => ({
    push: pushMock,
    replace: replaceMock,
  }),
  useSearchParams: () =>
    new URLSearchParams({
      id: 'inv-1',
      token: 'test-token',
    }),
}));

vi.mock('qrcode', () => ({
  default: {
    toDataURL: vi.fn().mockResolvedValue('data:image/png;base64,qr'),
  },
}));

function renderWithAcceptInviteMessages(ui: ReactNode) {
  return renderWithProviders(
    <NextIntlClientProvider
      locale="en"
      messages={{ common: enCommon, acceptInvite: enAcceptInvite, settings: enSettings }}
    >
      {ui}
    </NextIntlClientProvider>,
  );
}

describe('AcceptInviteFlow skip path', () => {
  beforeEach(() => {
    cleanup();
    replaceMock.mockReset();
    pushMock.mockReset();
    vi.stubGlobal(
      'fetch',
      vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
        const url = String(input);
        if (url.includes('/api/invite/validate')) {
          return {
            ok: true,
            json: async () => ({
              id: 'inv-1',
              email: 'mod@chisto.mk',
              firstName: 'Mod',
              lastName: 'Erator',
              role: 'SUPPORT',
              expiresAt: new Date(Date.now() + 3600_000).toISOString(),
            }),
          };
        }
        if (url.includes('/api/invite/accept')) {
          const body = JSON.parse(String(init?.body ?? '{}')) as Record<string, unknown>;
          expect(body.totpCode).toBeUndefined();
          return {
            ok: true,
            json: async () => ({ backupCodes: [] }),
          };
        }
        throw new Error(`Unexpected fetch: ${url}`);
      }),
    );
  });

  it('shows secure step after credentials and skips 2FA to dashboard', async () => {
    renderWithAcceptInviteMessages(<AcceptInviteFlow />);

    await screen.findByText('Welcome, Mod');

    fireEvent.change(screen.getByPlaceholderText('+38970123456'), {
      target: { value: '+38970123456' },
    });
    fireEvent.change(screen.getByLabelText(/^Password/), {
      target: { value: 'StrongPass123!' },
    });
    fireEvent.click(screen.getByRole('button', { name: 'Continue' }));

    expect(await screen.findByText('Secure your account')).toBeInTheDocument();
    fireEvent.click(screen.getByRole('button', { name: 'Skip for now' }));

    await waitFor(() => {
      expect(replaceMock).toHaveBeenCalledWith('/dashboard');
    });
  });
});

describe('MfaReminderBanner', () => {
  beforeEach(() => {
    cleanup();
    window.localStorage.clear();
  });

  it('shows when MFA is disabled and not dismissed', async () => {
    renderWithAcceptInviteMessages(<MfaReminderBanner mfaEnabled={false} />);
    expect(await screen.findByText('Strengthen your account security')).toBeInTheDocument();
  });

  it('hides when MFA is enabled', async () => {
    renderWithAcceptInviteMessages(<MfaReminderBanner mfaEnabled={true} />);
    await waitFor(() => {
      expect(screen.queryByText('Strengthen your account security')).not.toBeInTheDocument();
    });
  });

  it('hides after dismiss', async () => {
    renderWithAcceptInviteMessages(<MfaReminderBanner mfaEnabled={false} />);
    fireEvent.click(await screen.findByRole('button', { name: 'Not now' }));
    await waitFor(() => {
      expect(screen.queryByText('Strengthen your account security')).not.toBeInTheDocument();
    });
  });
});
