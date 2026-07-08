'use client';

import { useEffect, useMemo, useRef, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Icon } from '@/components/ui';
import type { NewsBodyBlock } from '../news-api-types';
import { isTransformableBlock, type TransformTarget } from '../lib/news-block-operations';
import {
  NewsBlockInsertMenuPanel,
  type NewsBlockInsertMenuSection,
} from './news-block-insert-menu';
import menuStyles from './news-block-insert-menu.module.css';
import styles from './news-block-transform-menu.module.css';

type NewsBlockTransformMenuProps = {
  block: NewsBodyBlock;
  disabled: boolean;
  buttonClassName: string;
  onTransform: (target: TransformTarget) => void;
};

type TargetOption = {
  target: TransformTarget;
  icon: 'document-text' | 'heading' | 'list';
  labelKey: `transform.${string}`;
  active: (block: NewsBodyBlock) => boolean;
};

const TARGET_OPTIONS: TargetOption[] = [
  {
    target: 'paragraph',
    icon: 'document-text',
    labelKey: 'transform.paragraph',
    active: (block) => block.type === 'paragraph',
  },
  {
    target: 'heading2',
    icon: 'heading',
    labelKey: 'transform.heading2',
    active: (block) => block.type === 'heading' && block.level === 2,
  },
  {
    target: 'heading3',
    icon: 'heading',
    labelKey: 'transform.heading3',
    active: (block) => block.type === 'heading' && block.level === 3,
  },
  {
    target: 'list',
    icon: 'list',
    labelKey: 'transform.list',
    active: (block) => block.type === 'list',
  },
  {
    target: 'quote',
    icon: 'document-text',
    labelKey: 'transform.quote',
    active: (block) => block.type === 'quote',
  },
];

/** Turn-into menu for text blocks (paragraph ↔ heading ↔ list). */
export function NewsBlockTransformMenu({
  block,
  disabled,
  buttonClassName,
  onTransform,
}: NewsBlockTransformMenuProps) {
  const t = useTranslations('news');
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);
  const panelRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    function onDocClick(event: MouseEvent) {
      if (!rootRef.current?.contains(event.target as Node)) setOpen(false);
    }
    document.addEventListener('mousedown', onDocClick);
    return () => document.removeEventListener('mousedown', onDocClick);
  }, [open]);

  const sections = useMemo<NewsBlockInsertMenuSection[]>(
    () => [
      {
        id: 'transform',
        label: t('transform.menuLabel'),
        items: TARGET_OPTIONS.filter((option) => !option.active(block)).map((option) => ({
          id: option.target,
          icon: option.icon,
          tone: 'text' as const,
          label: t(option.labelKey),
          description: t(`${option.labelKey}Description`),
          onSelect: () => {
            onTransform(option.target);
            setOpen(false);
          },
        })),
      },
    ],
    [block, onTransform, t],
  );

  if (!isTransformableBlock(block)) return null;

  return (
    <div ref={rootRef} className={styles.root}>
      <button
        type="button"
        className={buttonClassName}
        disabled={disabled}
        aria-label={t('form.transformBlock')}
        title={t('form.transformBlock')}
        aria-expanded={open}
        aria-haspopup="menu"
        onClick={() => setOpen((value) => !value)}
      >
        <Icon name="refresh" size={14} strokeWidth={2} aria-hidden />
      </button>
      <NewsBlockInsertMenuPanel
        open={open}
        sections={sections}
        ariaLabel={t('form.transformBlock')}
        panelRef={panelRef}
        align="end"
        className={menuStyles.compactPanel}
        onClose={() => setOpen(false)}
      />
    </div>
  );
}
