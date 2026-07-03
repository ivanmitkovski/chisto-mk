import { describe, expect, it, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { NextIntlClientProvider } from 'next-intl';
import { ToastProvider } from '@/components/ui';
import { RichTextLinkDialog } from './rich-text-link-dialog';
import enNews from '@/i18n/messages/en/news.json';
import enCommon from '@/i18n/messages/en/common.json';

function renderDialog(
  props: Partial<React.ComponentProps<typeof RichTextLinkDialog>> = {},
) {
  const onClose = vi.fn();
  render(
    <NextIntlClientProvider locale="en" messages={{ news: enNews, common: enCommon }}>
      <ToastProvider>
        <RichTextLinkDialog
          editor={null}
          snapshot={{
            from: 1,
            to: 7,
            empty: false,
            hadLink: false,
          }}
          open
          onClose={onClose}
          {...props}
        />
      </ToastProvider>
    </NextIntlClientProvider>,
  );
  return { onClose };
}

describe('RichTextLinkDialog', () => {
  it('focuses the URL field when text is already selected', async () => {
    const user = userEvent.setup();
    renderDialog();

    const urlInput = screen.getByLabelText('URL');
    await waitFor(() => {
      expect(urlInput).toHaveFocus();
    });

    await user.clear(urlInput);
    await user.type(urlInput, 'example.org');
    expect(urlInput).toHaveValue('example.org');
  });

  it('focuses the link text field when the selection is empty', async () => {
    const user = userEvent.setup();
    renderDialog({
      snapshot: {
        from: 4,
        to: 4,
        empty: true,
        hadLink: false,
      },
    });

    const linkTextInput = screen.getByLabelText('Link text');
    await waitFor(() => {
      expect(linkTextInput).toHaveFocus();
    });

    await user.type(linkTextInput, 'EKOHAB');
    expect(linkTextInput).toHaveValue('EKOHAB');
  });

  it('keeps the URL field editable after clicking it', async () => {
    const user = userEvent.setup();
    renderDialog();

    const urlInput = screen.getByLabelText('URL');
    await user.click(screen.getByText('Open in new tab'));
    await user.click(urlInput);
    await user.type(urlInput, 'chisto.mk');

    expect(urlInput).toHaveFocus();
    expect(urlInput).toHaveValue('https://chisto.mk');
  });
});
