import type { ReactElement } from 'react';
import { describe, expect, it, vi } from 'vitest';
import { fireEvent, render, screen } from '@testing-library/react';
import { NextIntlClientProvider } from 'next-intl';
import { DateTimePicker } from './date-time-picker';
import enUi from '@/i18n/messages/en/ui.json';

vi.mock('@/lib/i18n', () => ({
  useAdminBcp47Locale: () => 'en-US',
  formatAdminDateTime: () => 'Jun 24, 2026, 10:00 AM',
}));

function renderPicker(ui: ReactElement) {
  return render(
    <NextIntlClientProvider locale="en" messages={{ ui: enUi }}>
      {ui}
    </NextIntlClientProvider>,
  );
}

describe('DateTimePicker', () => {
  it('opens calendar and selects date with default time', () => {
    const onValueChange = vi.fn();
    renderPicker(
      <DateTimePicker label="Schedule" value="" onValueChange={onValueChange} />,
    );

    fireEvent.click(screen.getByRole('button', { name: /schedule/i }));
    expect(screen.getByRole('dialog', { name: 'Schedule' })).toBeInTheDocument();

    const dayButtons = screen.getAllByRole('gridcell').filter((btn) => !(btn as HTMLButtonElement).disabled);
    fireEvent.click(dayButtons[0]!);
    expect(onValueChange).toHaveBeenCalledWith(expect.stringMatching(/T10:00$/));
  });
});
