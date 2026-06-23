import { describe, expect, it, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { NextIntlClientProvider } from 'next-intl';
import { AlertsPanel } from './alerts-panel';

const setAlertRules = vi.fn();

vi.mock('@/components/ui', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@/components/ui')>();
  return {
    ...actual,
    useToast: () => ({ showToast: vi.fn() }),
  };
});

vi.mock('../hooks/use-active-users-live', () => ({
  useActiveUsersLive: () => ({
    alertRules: [
      {
        id: 'rule-1',
        metric: 'CONCURRENT',
        comparator: 'GT',
        threshold: 100,
        windowSeconds: 300,
        enabled: true,
        lastTriggeredAt: null,
      },
    ],
    setAlertRules,
    highlightedAlertId: null,
  }),
}));

vi.mock('../data/active-users-adapter.client', () => ({
  browserCreateAlertRule: vi.fn(),
  browserUpdateAlertRule: vi.fn(),
  browserDeleteAlertRule: vi.fn(),
}));

const messages = {
  common: {
    cancel: 'Cancel',
    edit: 'Edit',
    delete: 'Delete',
    error: 'Error',
    saved: 'Saved',
    saving: 'Saving',
    saveChanges: 'Save changes',
  },
  activeUsers: {
    alertsTitle: 'Alerts',
    alerts: {
      add: 'Add rule',
      createTitle: 'Create alert',
      editTitle: 'Edit alert',
      formDescription: 'Form',
      metricLabel: 'Metric',
      comparatorLabel: 'Comparator',
      thresholdLabel: 'Threshold',
      windowLabel: 'Window',
      enabledLabel: 'Enabled',
      enable: 'Enable',
      disable: 'Disable',
      create: 'Create',
      metrics: { CONCURRENT: 'Concurrent users' },
      comparators: { gt: 'Greater than', gte: 'GTE' },
    },
    noAlerts: 'No alerts',
    enabled: 'Enabled',
    disabled: 'Disabled',
  },
};

describe('AlertsPanel', () => {
  it('renders alert rules and opens create modal', async () => {
    const user = userEvent.setup();
    render(
      <NextIntlClientProvider locale="en" messages={messages}>
        <AlertsPanel />
      </NextIntlClientProvider>,
    );

    expect(screen.getByText('Concurrent users')).toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: 'Add rule' }));
    expect(screen.getByText('Create alert')).toBeInTheDocument();
  });
});
