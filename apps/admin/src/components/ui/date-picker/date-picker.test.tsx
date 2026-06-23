import type { ReactElement } from 'react';
import { describe, expect, it, vi } from 'vitest';
import { fireEvent, render, screen } from '@testing-library/react';
import { NextIntlClientProvider } from 'next-intl';
import { DatePicker } from './date-picker';
import enUi from '@/i18n/messages/en/ui.json';

vi.mock('@/lib/i18n', () => ({
  useAdminBcp47Locale: () => 'en-US',
  formatAdminDate: () => 'Jun 22, 2026',
}));

function renderPicker(ui: ReactElement) {
  return render(
    <NextIntlClientProvider locale="en" messages={{ ui: enUi }}>
      {ui}
    </NextIntlClientProvider>,
  );
}

describe('DatePicker', () => {
  it('opens the calendar popover and selects a date', () => {
    const onValueChange = vi.fn();
    renderPicker(
      <DatePicker label="Start date" value="" onValueChange={onValueChange} />,
    );

    fireEvent.click(screen.getByRole('button', { name: /start date/i }));
    expect(screen.getByRole('dialog', { name: 'Start date' })).toBeInTheDocument();

    const dayButtons = screen.getAllByRole('gridcell');
    fireEvent.click(dayButtons[10]!);
    expect(onValueChange).toHaveBeenCalled();
  });
});
