import { beforeAll, describe, expect, it, vi } from 'vitest';
import { fireEvent, render, screen } from '@testing-library/react';
import { NextIntlClientProvider } from 'next-intl';
import { ToastProvider } from '@/components/ui';
import enNews from '@/i18n/messages/en/news.json';
import enUi from '@/i18n/messages/en/ui.json';
import type { NewsBodyBlock } from '../news-api-types';
import { NewsBlockList } from './news-block-list';

const messages = { news: enNews, ui: enUi };

beforeAll(() => {
  if (typeof globalThis.ResizeObserver === 'undefined') {
    globalThis.ResizeObserver = class {
      observe() {}
      unobserve() {}
      disconnect() {}
    } as unknown as typeof ResizeObserver;
  }
});

function renderList(blocks: NewsBodyBlock[], onChange = vi.fn()) {
  render(
    <NextIntlClientProvider locale="en" messages={messages}>
      <ToastProvider>
        <NewsBlockList
          blocks={blocks}
          locale="en"
          media={[]}
          readOnly={false}
          actionsDisabled={false}
          onChange={onChange}
        />
      </ToastProvider>
    </NextIntlClientProvider>,
  );
  return onChange;
}

const heading: NewsBodyBlock = { id: 'h1', type: 'heading', level: 2, text: 'Section' };
const list: NewsBodyBlock = { id: 'l1', type: 'list', ordered: false, items: ['One'] };

describe('NewsBlockList block chrome', () => {
  it('deletes a text block instantly and offers Undo', () => {
    const onChange = renderList([heading, list]);

    fireEvent.click(screen.getAllByRole('button', { name: 'Remove' })[0]!);
    expect(onChange).toHaveBeenCalledWith([list]);

    // Undo restores the heading at its original position.
    fireEvent.click(screen.getByRole('button', { name: 'Undo' }));
    const lastCall = onChange.mock.calls.at(-1)![0] as NewsBodyBlock[];
    expect(lastCall.map((b) => b.id)).toContain('h1');
  });

  it('duplicates a block with a fresh id', () => {
    const onChange = renderList([heading]);
    fireEvent.click(screen.getByRole('button', { name: 'Duplicate block' }));
    const next = onChange.mock.calls.at(-1)![0] as NewsBodyBlock[];
    expect(next).toHaveLength(2);
    expect(next[1]).toMatchObject({ type: 'heading', text: 'Section' });
    expect(next[1]!.id).not.toBe('h1');
  });

  it('transforms a heading into a list via the turn-into menu', () => {
    const onChange = renderList([heading]);
    fireEvent.click(screen.getByRole('button', { name: 'Turn into…' }));
    fireEvent.click(screen.getByRole('menuitem', { name: /List/ }));
    const next = onChange.mock.calls.at(-1)![0] as NewsBodyBlock[];
    expect(next[0]).toMatchObject({ type: 'list', items: ['Section'] });
  });

  it('inserts a paragraph after a heading on Enter', () => {
    const onChange = renderList([heading]);
    const input = screen.getByPlaceholderText(enNews.form.headingPlaceholder);
    fireEvent.keyDown(input, { key: 'Enter' });
    const next = onChange.mock.calls.at(-1)![0] as NewsBodyBlock[];
    expect(next).toHaveLength(2);
    expect(next[1]).toMatchObject({ type: 'paragraph', text: '' });
  });

  it('keeps the confirm dialog for media blocks', () => {
    const image: NewsBodyBlock = { id: 'i1', type: 'image', mediaId: 'm1' };
    const onChange = renderList([image]);
    fireEvent.click(screen.getByRole('button', { name: 'Remove' }));
    // No immediate change; a confirmation dialog opens instead.
    expect(onChange).not.toHaveBeenCalled();
    expect(screen.getByRole('dialog')).toBeTruthy();
  });
});
