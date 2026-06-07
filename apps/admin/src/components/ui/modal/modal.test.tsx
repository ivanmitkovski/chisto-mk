import { describe, expect, it, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { NextIntlClientProvider } from 'next-intl';
import { Modal } from './modal';

import enCommon from '@/i18n/messages/en/common.json';

function renderModal(props: Partial<React.ComponentProps<typeof Modal>> = {}) {
  const onClose = vi.fn();
  render(
    <NextIntlClientProvider locale="en" messages={{ common: enCommon }}>
      <Modal
        open
        title="Confirm action"
        description="This cannot be undone."
        onClose={onClose}
        {...props}
      />
    </NextIntlClientProvider>,
  );
  return { onClose };
}

describe('Modal keyboard interaction', () => {
  it('closes when Escape is pressed', async () => {
    const user = userEvent.setup();
    const { onClose } = renderModal();

    expect(screen.getByRole('dialog', { name: 'Confirm action' })).toBeInTheDocument();
    await user.keyboard('{Escape}');

    expect(onClose).toHaveBeenCalledTimes(1);
  });
});
