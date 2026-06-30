import { describe, expect, it } from 'vitest';
import { useState } from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { NextIntlClientProvider } from 'next-intl';
import { ToastProvider } from '@/components/ui';
import { useOptimisticMutation } from './use-optimistic-mutation';

import enErrors from '@/i18n/messages/en/errors.json';
import enUi from '@/i18n/messages/en/ui.json';

function OptimisticHarness() {
  const [value, setValue] = useState(0);
  const { run } = useOptimisticMutation({
    mutate: async () => {
      throw new Error('mutation failed');
    },
    errorToast: { title: 'Failed', message: 'Try again' },
  });

  return (
    <div>
      <span data-testid="value">{value}</span>
      <button
        type="button"
        onClick={() =>
          void run(undefined, {
            optimistic: () => setValue(1),
            rollback: () => setValue(0),
          })
        }
      >
        Run
      </button>
    </div>
  );
}

describe('useOptimisticMutation', () => {
  it('rolls back optimistic state when the mutation fails', async () => {
    const user = userEvent.setup();
    render(
      <NextIntlClientProvider locale="en" messages={{ errors: enErrors, ui: enUi }}>
        <ToastProvider>
          <OptimisticHarness />
        </ToastProvider>
      </NextIntlClientProvider>,
    );

    await user.click(screen.getByRole('button', { name: 'Run' }));

    await waitFor(() => {
      expect(screen.getByTestId('value')).toHaveTextContent('0');
    });
  });
});
