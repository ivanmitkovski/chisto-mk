'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Icon } from '@/components/ui';
import type { NewsBodyBlock } from '../news-api-types';
import {
  BLOCK_INSERT_OPTIONS,
  createBlockFromType,
  type BlockInsertType,
} from '../lib/news-block-insert-config';
import { insertBlockAt } from '../lib/news-block-factory';
import {
  NewsBlockInsertMenuPanel,
  type NewsBlockInsertMenuSection,
} from './news-block-insert-menu';
import styles from './news-block-insert-menu.module.css';

export type { BlockInsertType } from '../lib/news-block-insert-config';

type NewsBlockInserterProps = {
  index: number;
  readOnly: boolean;
  atBlockLimit: boolean;
  prominent?: boolean;
  onInsert: (index: number, block: NewsBodyBlock) => void;
  onBlockLimit?: () => void;
};

export function NewsBlockInserter({
  index,
  readOnly,
  atBlockLimit,
  prominent = false,
  onInsert,
  onBlockLimit,
}: NewsBlockInserterProps) {
  const t = useTranslations('news');
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);
  const panelRef = useRef<HTMLDivElement>(null);

  const handleInsert = useCallback(
    (type: BlockInsertType) => {
      if (atBlockLimit) {
        onBlockLimit?.();
        setOpen(false);
        return;
      }
      onInsert(index, createBlockFromType(type));
      setOpen(false);
    },
    [atBlockLimit, index, onBlockLimit, onInsert],
  );

  const sections = useMemo<NewsBlockInsertMenuSection[]>(
    () => [
      {
        id: 'blocks',
        label: t('toolbar.insertBlocks'),
        items: BLOCK_INSERT_OPTIONS.map((option) => ({
          id: option.type,
          icon: option.icon,
          tone: option.tone,
          label: t(option.labelKey),
          description: t(option.descriptionKey),
          onSelect: () => handleInsert(option.type),
        })),
      },
    ],
    [handleInsert, t],
  );

  useEffect(() => {
    if (!open) return;
    function onDocClick(event: MouseEvent) {
      if (!rootRef.current?.contains(event.target as Node)) setOpen(false);
    }
    function onKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape') setOpen(false);
    }
    document.addEventListener('mousedown', onDocClick);
    window.addEventListener('keydown', onKeyDown);
    return () => {
      document.removeEventListener('mousedown', onDocClick);
      window.removeEventListener('keydown', onKeyDown);
    };
  }, [open]);

  if (readOnly) return null;

  const rootClass = [
    styles.inlineRoot,
    prominent ? styles.inlineProminent : '',
    open ? styles.inlineRootOpen : '',
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <div ref={rootRef} className={rootClass}>
      <span className={styles.inlineRule} aria-hidden />
      <button
        type="button"
        className={styles.inlineTrigger}
        aria-label={t('form.insertBlock')}
        aria-expanded={open}
        aria-haspopup="menu"
        onClick={() => setOpen((value) => !value)}
      >
        <Icon name="plus" size={14} strokeWidth={2.25} />
      </button>
      <NewsBlockInsertMenuPanel
        open={open}
        sections={sections}
        ariaLabel={t('form.insertBlock')}
        panelRef={panelRef}
        align="center"
        onClose={() => setOpen(false)}
      />
    </div>
  );
}

export function insertBlockIntoBody(
  body: NewsBodyBlock[],
  index: number,
  block: NewsBodyBlock,
): NewsBodyBlock[] {
  return insertBlockAt(body, index, block);
}
