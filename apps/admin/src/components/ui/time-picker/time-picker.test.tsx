import type { ReactElement } from 'react';
import { describe, expect, it, vi } from 'vitest';
import { fireEvent, render, screen, within } from '@testing-library/react';
import { NextIntlClientProvider } from 'next-intl';
import { TimePicker, scrollWheelToOption } from './time-picker';
import enUi from '@/i18n/messages/en/ui.json';

function renderPicker(ui: ReactElement) {
  return render(
    <NextIntlClientProvider locale="en" messages={{ ui: enUi }}>
      {ui}
    </NextIntlClientProvider>,
  );
}

describe('TimePicker', () => {
  it('selects hour', () => {
    const onChange = vi.fn();
    renderPicker(<TimePicker value="10:00" onChange={onChange} aria-label="Time" />);
    fireEvent.click(screen.getByRole('option', { name: '11' }));
    expect(onChange).toHaveBeenCalledWith('11:00');
  });

  it('selects minute', () => {
    const onChange = vi.fn();
    renderPicker(<TimePicker value="11:00" onChange={onChange} aria-label="Time" />);
    const minuteList = screen.getByRole('listbox', { name: 'Minute' });
    fireEvent.click(within(minuteList).getByRole('option', { name: '15' }));
    expect(onChange).toHaveBeenCalledWith('11:15');
  });

  it('aligns wheels locally without scrollIntoView', () => {
    const scrollIntoView = vi.fn();
    Object.defineProperty(HTMLElement.prototype, 'scrollIntoView', {
      configurable: true,
      value: scrollIntoView,
    });
    renderPicker(<TimePicker value="10:00" onChange={vi.fn()} aria-label="Time" />);
    expect(scrollIntoView).not.toHaveBeenCalled();
  });

  it('scrolls inside the list container only', () => {
    const list = document.createElement('div');
    list.style.height = '100px';
    Object.defineProperty(list, 'clientHeight', { value: 100, configurable: true });
    Object.defineProperty(list, 'scrollHeight', { value: 500, configurable: true });

    const option = document.createElement('button');
    option.id = 'hour-10';
    Object.defineProperty(option, 'offsetHeight', { value: 36, configurable: true });
    Object.defineProperty(option, 'offsetTop', { value: 360, configurable: true });
    list.appendChild(option);
    document.body.appendChild(list);

    list.scrollTo = (options: ScrollToOptions) => {
      list.scrollTop = options.top ?? 0;
    };

    scrollWheelToOption(list, 'hour-10', 'auto');
    expect(list.scrollTop).toBe(328);

    list.remove();
  });
});
