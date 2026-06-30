/**
 * @vitest-environment jsdom
 */
import { describe, expect, it, afterEach } from 'vitest';
import { cleanup, screen } from '@testing-library/react';
import { NextIntlClientProvider } from 'next-intl';
import { OperationsPushStatusRow } from './operations-push-status-row';
import { renderWithProviders } from '@/test/render-with-providers';
import enOperations from '@/i18n/messages/en/operations.json';

describe('OperationsPushStatusRow', () => {
  afterEach(() => {
    cleanup();
  });

  it('renders remediation when push diagnostics include guidance', () => {
    renderWithProviders(
      <NextIntlClientProvider locale="en" messages={{ operations: enOperations }}>
        <OperationsPushStatusRow
        pushDiagnostics={{
          fcmEnabled: true,
          fcmReady: false,
          projectId: null,
          credentialStatus: 'invalid_json',
          credentialParseError: 'Unexpected token',
          deadLetterTotal: 0,
          queueDepth: 0,
          activeLeases: 0,
          registeredDeviceTokens: 0,
          workerStatus: { expected: true, running: false, stale: true },
          remediation: 'Fix FIREBASE_SERVICE_ACCOUNT_JSON formatting.',
        }}
        pushHealth={null}
        />
      </NextIntlClientProvider>,
    );

    expect(screen.getByText('Fix FIREBASE_SERVICE_ACCOUNT_JSON formatting.')).toBeInTheDocument();
    expect(screen.getByText(/FCM not ready/i)).toBeInTheDocument();
  });
});
