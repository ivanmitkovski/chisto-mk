'use client';

import { useRef, type KeyboardEvent } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Icon } from '@/components/ui';
import type { NewsBodyBlock } from '../news-api-types';
import styles from './news-list-block-editor.module.css';

const MAX_LIST_ITEMS = 20;

type ListBlock = Extract<NewsBodyBlock, { type: 'list' }>;

type NewsListBlockEditorProps = {
  block: ListBlock;
  readOnly: boolean;
  busy: boolean;
  variant?: 'classic' | 'document';
  onChange: (block: ListBlock) => void;
};

function listMarker(ordered: boolean, index: number): string {
  return ordered ? `${index + 1}.` : '•';
}

export function NewsListBlockEditor({
  block,
  readOnly,
  busy,
  variant = 'classic',
  onChange,
}: NewsListBlockEditorProps) {
  const t = useTranslations('news');
  const inputRefs = useRef<Array<HTMLInputElement | null>>([]);
  const isDocument = variant === 'document';

  function updateItem(itemIndex: number, value: string) {
    const items = [...block.items];
    items[itemIndex] = value;
    onChange({ ...block, items });
  }

  function removeItem(itemIndex: number) {
    if (block.items.length <= 1) return;
    onChange({ ...block, items: block.items.filter((_, i) => i !== itemIndex) });
    const focusIndex = Math.max(0, itemIndex - 1);
    requestAnimationFrame(() => inputRefs.current[focusIndex]?.focus());
  }

  function addItem(afterIndex?: number) {
    if (block.items.length >= MAX_LIST_ITEMS) return;
    const items = [...block.items];
    const insertAt = afterIndex === undefined ? items.length : afterIndex + 1;
    items.splice(insertAt, 0, '');
    onChange({ ...block, items });
    requestAnimationFrame(() => inputRefs.current[insertAt]?.focus());
  }

  function handleItemKeyDown(
    event: KeyboardEvent<HTMLInputElement>,
    itemIndex: number,
    value: string,
  ) {
    if (readOnly) return;
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      if (itemIndex < block.items.length - 1) {
        inputRefs.current[itemIndex + 1]?.focus();
      } else {
        addItem(itemIndex);
      }
    }
    if (event.key === 'Backspace' && value === '' && block.items.length > 1) {
      event.preventDefault();
      removeItem(itemIndex);
    }
  }

  const rootClass = [styles.root, isDocument ? styles.rootDocument : styles.rootClassic]
    .filter(Boolean)
    .join(' ');

  return (
    <div className={rootClass}>
      {!readOnly ? (
        <div className={isDocument ? styles.typeRowDocument : styles.typeRow} role="group" aria-label={t('form.listTypeAria')}>
          <div className={styles.typeToggle}>
            <Button
              type="button"
              size="sm"
              variant={block.ordered ? 'outline' : 'solid'}
              disabled={busy}
              aria-pressed={!block.ordered}
              onClick={() => onChange({ ...block, ordered: false })}
            >
              {t('form.blockBulletList')}
            </Button>
            <Button
              type="button"
              size="sm"
              variant={block.ordered ? 'solid' : 'outline'}
              disabled={busy}
              aria-pressed={block.ordered}
              onClick={() => onChange({ ...block, ordered: true })}
            >
              {t('form.blockOrderedList')}
            </Button>
          </div>
        </div>
      ) : (
        <p className={styles.readOnlyType}>
          {block.ordered ? t('form.blockOrderedList') : t('form.blockBulletList')}
        </p>
      )}

      <ul className={styles.items} aria-label={t('form.listItemsAria')}>
        {block.items.map((item, itemIndex) => (
          <li key={`${block.id}-item-${itemIndex}`} className={styles.itemRow}>
            <span className={styles.marker} aria-hidden>
              {listMarker(block.ordered, itemIndex)}
            </span>
            <input
              ref={(node) => {
                inputRefs.current[itemIndex] = node;
              }}
              type="text"
              className={isDocument ? styles.itemInputDocument : styles.itemInputClassic}
              value={item}
              onChange={(e) => updateItem(itemIndex, e.target.value)}
              onKeyDown={(e) => handleItemKeyDown(e, itemIndex, item)}
              disabled={readOnly || busy}
              maxLength={500}
              placeholder={t('form.listItemPlaceholder')}
              aria-label={t('form.listItemAria', { index: itemIndex + 1 })}
            />
            {!readOnly && block.items.length > 1 ? (
              <button
                type="button"
                className={styles.removeItemBtn}
                disabled={busy}
                onClick={() => removeItem(itemIndex)}
                aria-label={t('form.removeListItem')}
              >
                <Icon name="x" size={14} strokeWidth={2} aria-hidden />
              </button>
            ) : null}
          </li>
        ))}
      </ul>

      {!readOnly ? (
        <div className={styles.footer}>
          <Button
            type="button"
            variant="ghost"
            size="sm"
            className={styles.addItemBtn}
            disabled={busy || block.items.length >= MAX_LIST_ITEMS}
            onClick={() => addItem()}
          >
            <Icon name="plus" size={14} strokeWidth={2} aria-hidden />
            {t('form.addListItem')}
          </Button>
          {block.items.length >= MAX_LIST_ITEMS ? (
            <span className={styles.limitHint}>{t('form.listItemLimit')}</span>
          ) : null}
        </div>
      ) : null}
    </div>
  );
}
