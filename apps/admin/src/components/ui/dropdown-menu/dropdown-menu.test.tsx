import { describe, expect, it } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { NextIntlClientProvider } from 'next-intl';
import { DropdownMenu } from './dropdown-menu';

import enCommon from '@/i18n/messages/en/common.json';

function renderMenu() {
  render(
    <NextIntlClientProvider locale="en" messages={{ common: enCommon }}>
      <DropdownMenu label="Layers" panelAriaLabel="Map layers">
        <button type="button" role="menuitem">
          Reports
        </button>
        <button type="button" role="menuitem">
          Sites
        </button>
      </DropdownMenu>
    </NextIntlClientProvider>,
  );
}

describe('DropdownMenu keyboard interaction', () => {
  it('opens from the trigger and closes on Escape', async () => {
    const user = userEvent.setup();
    renderMenu();

    const trigger = screen.getByRole('button', { name: 'Layers' });
    expect(trigger).toHaveAttribute('aria-expanded', 'false');

    await user.click(trigger);
    expect(trigger).toHaveAttribute('aria-expanded', 'true');
    expect(screen.getByRole('menu', { name: 'Map layers' })).toBeInTheDocument();

    await user.keyboard('{Escape}');
    await waitFor(() => {
      expect(trigger).toHaveAttribute('aria-expanded', 'false');
    });
  });
});
