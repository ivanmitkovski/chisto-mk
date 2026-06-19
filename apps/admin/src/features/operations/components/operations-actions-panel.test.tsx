/**
 * @vitest-environment jsdom
 */
import { describe, expect, it, afterEach } from 'vitest';
import { cleanup, screen } from '@testing-library/react';
import { NextIntlClientProvider } from 'next-intl';
import { StatusDot } from '@/components/ui';
import { renderWithProviders } from '@/test/render-with-providers';
import enOperations from '@/i18n/messages/en/operations.json';
import styles from './operations-actions-panel.module.css';

function TestPushFunnelContent() {
function translateTestPush(key: 'inboxCreated' | 'fcmReady' | 'activeTokens', values?: { count?: number }) {
  const message = enOperations.testPush[key];
  if (key === 'activeTokens' && values?.count != null) {
    return message.replace('{count}', String(values.count));
  }
  return message;
}

  const result = {
    funnel: {
      inboxCreated: true,
      pushEnabled: true,
      fcmReady: false,
      activeTokenCount: 0,
      outboxEnqueued: 0,
    },
    remediation: 'Register a device token for your admin account.',
  };

  return (
    <div>
      <ul className={styles.funnelList}>
        <li>
          <StatusDot status={result.funnel.inboxCreated ? 'ok' : 'critical'} label={translateTestPush('inboxCreated')} />
        </li>
        <li>
          <StatusDot status={result.funnel.fcmReady ? 'ok' : 'critical'} label={translateTestPush('fcmReady')} />
        </li>
        <li>{translateTestPush('activeTokens', { count: result.funnel.activeTokenCount })}</li>
      </ul>
      {result.remediation ? <p className={styles.funnelRemediation}>{result.remediation}</p> : null}
    </div>
  );
}

describe('OperationsActionsPanel funnel content', () => {
  afterEach(() => {
    cleanup();
  });

  it('shows funnel rows and remediation guidance', () => {
    renderWithProviders(
      <NextIntlClientProvider locale="en" messages={{ operations: enOperations }}>
        <TestPushFunnelContent />
      </NextIntlClientProvider>,
    );

    expect(screen.getByText('Inbox notification created')).toBeInTheDocument();
    expect(screen.getByText('FCM ready')).toBeInTheDocument();
    expect(screen.getByText('Active device tokens: 0')).toBeInTheDocument();
    expect(screen.getByText('Register a device token for your admin account.')).toBeInTheDocument();
  });
});
