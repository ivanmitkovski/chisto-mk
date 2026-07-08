'use client';

import { useTranslations } from 'next-intl';
import type { NewsBodyBlock } from '../news-api-types';
import styles from './news-quote-block-editor.module.css';

type QuoteBlock = Extract<NewsBodyBlock, { type: 'quote' }>;

type NewsQuoteBlockEditorProps = {
  block: QuoteBlock;
  readOnly: boolean;
  autoFocus?: boolean | undefined;
  onChange: (block: QuoteBlock) => void;
};

export function NewsQuoteBlockEditor({
  block,
  readOnly,
  autoFocus = false,
  onChange,
}: NewsQuoteBlockEditorProps) {
  const t = useTranslations('news');

  return (
    <figure className={styles.root}>
      <blockquote className={styles.quote}>
        <textarea
          className={styles.quoteText}
          value={block.text}
          onChange={(e) => onChange({ ...block, text: e.target.value })}
          disabled={readOnly}
          rows={3}
          maxLength={2000}
          placeholder={t('form.quotePlaceholder')}
          aria-label={t('form.quoteText')}
          {...(autoFocus ? { autoFocus: true } : {})}
        />
      </blockquote>
      <input
        type="text"
        className={styles.attribution}
        value={block.attribution ?? ''}
        onChange={(e) => {
          const attribution = e.target.value;
          const next: QuoteBlock = {
            type: 'quote',
            text: block.text,
            ...(block.id !== undefined ? { id: block.id } : {}),
            ...(attribution.trim() ? { attribution } : {}),
          };
          onChange(next);
        }}
        disabled={readOnly}
        maxLength={200}
        placeholder={t('form.quoteAttributionPlaceholder')}
        aria-label={t('form.quoteAttribution')}
      />
    </figure>
  );
}
