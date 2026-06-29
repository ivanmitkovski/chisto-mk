'use client';

import type { Announcements } from '@dnd-kit/core';
import { useMemo } from 'react';
import { useTranslations } from 'next-intl';
import { blockTypeLabel } from '../lib/news-block-display';
import type { NewsBodyBlock } from '../news-api-types';

function findBlockIndex(blocks: NewsBodyBlock[], id: string | number): number {
  return blocks.findIndex((block, index) => (block.id ?? `block-${index}`) === String(id));
}

export function useNewsBlockDragAnnouncements(blocks: NewsBodyBlock[]): Announcements {
  const t = useTranslations('news');

  return useMemo(
    () => ({
      onDragStart({ active }) {
        const index = findBlockIndex(blocks, active.id);
        const block = index >= 0 ? blocks[index] : null;
        if (!block) return;
        return t('drag.pickedUp', {
          type: blockTypeLabel(block, t),
          position: index + 1,
        });
      },
      onDragOver({ active, over }) {
        if (!over) return;
        const activeIndex = findBlockIndex(blocks, active.id);
        const overIndex = findBlockIndex(blocks, over.id);
        const block = activeIndex >= 0 ? blocks[activeIndex] : null;
        if (!block || overIndex < 0) return;
        return t('drag.over', {
          type: blockTypeLabel(block, t),
          position: overIndex + 1,
        });
      },
      onDragEnd({ active, over }) {
        const activeIndex = findBlockIndex(blocks, active.id);
        const block = activeIndex >= 0 ? blocks[activeIndex] : null;
        if (!block) return;
        if (!over || active.id === over.id) {
          return t('drag.droppedSame', { type: blockTypeLabel(block, t) });
        }
        const overIndex = findBlockIndex(blocks, over.id);
        return t('drag.dropped', {
          type: blockTypeLabel(block, t),
          position: overIndex >= 0 ? overIndex + 1 : activeIndex + 1,
        });
      },
      onDragCancel({ active }) {
        const index = findBlockIndex(blocks, active.id);
        const block = index >= 0 ? blocks[index] : null;
        if (!block) return;
        return t('drag.cancelled', { type: blockTypeLabel(block, t) });
      },
    }),
    [blocks, t],
  );
}
