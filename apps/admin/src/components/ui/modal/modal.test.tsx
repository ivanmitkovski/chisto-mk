import { describe, expect, it, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { createRef } from 'react';
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

  it('focuses initialFocusRef when provided', async () => {
    const inputRef = createRef<HTMLInputElement>();
    renderModal({
      initialFocusRef: inputRef,
      children: <input ref={inputRef} aria-label="Target field" defaultValue="" />,
    });

    await waitFor(() => {
      expect(screen.getByLabelText('Target field')).toHaveFocus();
    });
  });
});
