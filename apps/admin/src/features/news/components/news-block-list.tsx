'use client';

import {
  DndContext,
  DragOverlay,
  KeyboardSensor,
  MeasuringStrategy,
  PointerSensor,
  TouchSensor,
  defaultDropAnimationSideEffects,
  type DragEndEvent,
  type DragPendingEvent,
  type DragStartEvent,
  useDndContext,
  useSensor,
  useSensors,
} from '@dnd-kit/core';
import { restrictToVerticalAxis, restrictToWindowEdges } from '@dnd-kit/modifiers';
import {
  SortableContext,
  arrayMove,
  sortableKeyboardCoordinates,
  useSortable,
  verticalListSortingStrategy,
} from '@dnd-kit/sortable';
import { CSS, getEventCoordinates } from '@dnd-kit/utilities';
import { useTranslations } from 'next-intl';
import { useCallback, useEffect, useRef, useState } from 'react';
import { Icon, useToast } from '@/components/ui';
import type { NewsBodyBlock, NewsMediaDto } from '../news-api-types';
import { useNewsBlockDragAnnouncements } from '../hooks/use-news-block-drag-announcements';
import { newsBlockCollisionDetection } from '../lib/news-block-drag-collision';
import { resolveBlockDropEdge } from '../lib/news-block-drop-edge';
import {
  setBlockDragPickupContext,
  snapBlockOverlayToPickup,
} from '../lib/news-block-drag-overlay-modifiers';
import { createBlockFromType } from '../lib/news-block-insert-config';
import { MAX_BODY_BLOCKS } from '../lib/news-post-policy';
import { insertBlockIntoBody, NewsBlockInserter } from './news-block-inserter';
import { NewsBlockInsertStarter } from './news-block-insert-starter';
import { NewsBlockDragOverlayRow } from './news-block-drag-overlay-row';
import { NewsBlockDragOverlayPortal } from './news-block-drag-overlay-portal';
import { NewsBlockRemoveDialog } from './news-block-remove-dialog';
import { NewsBodyBlockEditor } from './news-body-block-editor';
import styles from './news-block-list.module.css';

type NewsBlockListProps = {
  blocks: NewsBodyBlock[];
  locale: string;
  media: NewsMediaDto[];
  readOnly: boolean;
  actionsDisabled: boolean;
  documentMode?: boolean;
  uploadingBlockKind?: 'inline_image' | 'inline_video' | null;
  uploadValidationErrors?: Partial<Record<'inline_image' | 'inline_video', string>>;
  onChange: (blocks: NewsBodyBlock[]) => void;
  onUploadForBlock?: (blockIndex: number, file: File, blockType: 'image' | 'video') => void;
  onUploadForGallerySlot?: (blockIndex: number, itemIndex: number, file: File) => void;
  uploadingGallerySlot?: { blockIndex: number; itemIndex: number } | null | undefined;
  blockUploadPreview?: { blockIndex: number; url: string } | null | undefined;
};

type SortableRowProps = {
  sortableId: string;
  sortableIds: string[];
  block: NewsBodyBlock;
  index: number;
  total: number;
  media: NewsMediaDto[];
  readOnly: boolean;
  actionsDisabled: boolean;
  activeIndex: number;
  documentMode?: boolean;
  uploadingBlockKind?: 'inline_image' | 'inline_video' | null | undefined;
  uploadValidationErrors?: Partial<Record<'inline_image' | 'inline_video', string>> | undefined;
  uploadingGallerySlot?: { blockIndex: number; itemIndex: number } | null | undefined;
  blockUploadPreview?: { blockIndex: number; url: string } | null | undefined;
  onChange: (block: NewsBodyBlock) => void;
  onRequestRemove: () => void;
  onUploadForBlock?: ((file: File) => void) | undefined;
  onUploadForGallerySlot?: ((itemIndex: number, file: File) => void) | undefined;
};

function SortableBlockRow({
  sortableId,
  sortableIds,
  block,
  index,
  total,
  media,
  readOnly,
  actionsDisabled,
  activeIndex,
  documentMode = false,
  uploadingBlockKind,
  uploadValidationErrors,
  uploadingGallerySlot,
  blockUploadPreview,
  onChange,
  onRequestRemove,
  onUploadForBlock,
  onUploadForGallerySlot,
}: SortableRowProps) {
  const t = useTranslations('news');
  const rowRef = useRef<HTMLDivElement>(null);
  const [placeholderHeight, setPlaceholderHeight] = useState<number | undefined>();
  const { over } = useDndContext();
  const dragDisabled = readOnly || actionsDisabled;

  const {
    attributes,
    listeners,
    setNodeRef,
    setActivatorNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({
    id: sortableId,
    disabled: dragDisabled,
  });

  const overIndex = over ? sortableIds.indexOf(String(over.id)) : -1;
  const dropEdge = resolveBlockDropEdge(activeIndex, overIndex, index);
  const uploadKind = block.type === 'video' ? 'inline_video' : 'inline_image';
  const blockUploadBusy = uploadingBlockKind === uploadKind;
  const gallerySlotUpload =
    block.type === 'gallery' && uploadingGallerySlot?.blockIndex === index
      ? uploadingGallerySlot.itemIndex
      : null;
  const uploadError =
    block.type === 'gallery'
      ? gallerySlotUpload !== null
        ? null
        : uploadValidationErrors?.inline_image ?? null
      : blockUploadBusy
        ? null
        : uploadValidationErrors?.[uploadKind] ?? null;

  useEffect(() => {
    if (isDragging && rowRef.current) {
      setPlaceholderHeight(rowRef.current.offsetHeight);
      return;
    }
    setPlaceholderHeight(undefined);
  }, [isDragging]);

  const setWrapRef = (node: HTMLDivElement | null) => {
    setNodeRef(node);
    rowRef.current = node;
  };

  const style = {
    transform: CSS.Translate.toString(transform),
    transition: isDragging ? undefined : transition,
    ...(isDragging && placeholderHeight ? { minHeight: placeholderHeight } : {}),
  };

  const rowClass = [
    styles.row,
    documentMode ? styles.rowDocument : '',
    isDragging ? styles.rowDragging : '',
  ]
    .filter(Boolean)
    .join(' ');
  const wrapClass = [
    styles.rowWrap,
    documentMode ? styles.rowWrapDocument : '',
    dropEdge === 'before' ? styles.rowDropBefore : '',
    dropEdge === 'after' ? styles.rowDropAfter : '',
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <div
      ref={setWrapRef}
      style={style}
      className={wrapClass}
      data-sortable-id={sortableId}
      data-dragging={isDragging || undefined}
    >
    <div className={rowClass}>
      {!readOnly ? (
        <button
          ref={setActivatorNodeRef}
          type="button"
          className={documentMode ? styles.dragHandleDocument : styles.dragHandle}
          aria-label={t('form.dragBlock')}
          disabled={dragDisabled}
          {...attributes}
          {...listeners}
        >
          <Icon name="arrow-up-down" size={14} strokeWidth={2} aria-hidden />
        </button>
      ) : null}
      <div className={styles.rowContent}>
        <NewsBodyBlockEditor
          block={block}
          index={index}
          total={total}
          media={media}
          readOnly={readOnly}
          busy={actionsDisabled}
          variant="document"
          uploadBusy={blockUploadBusy}
          uploadError={uploadError}
          localPreviewSrc={
            blockUploadPreview?.blockIndex === index ? blockUploadPreview.url : null
          }
          onChange={onChange}
          onRemove={onRequestRemove}
          onMoveUp={() => {}}
          onMoveDown={() => {}}
          {...(onUploadForBlock && (block.type === 'image' || block.type === 'video')
            ? { onUploadForBlock, onReplaceForBlock: onUploadForBlock }
            : {})}
          {...(onUploadForGallerySlot && block.type === 'gallery'
            ? {
                onUploadForGallerySlot,
                uploadGallerySlotIndex: gallerySlotUpload,
              }
            : {})}
        />
      </div>
      {!readOnly ? (
        <button
          type="button"
          className={documentMode ? styles.removeBtnDocument : styles.removeBtn}
          disabled={actionsDisabled}
          onClick={onRequestRemove}
          aria-label={t('form.removeBlock')}
        >
          <Icon name="x" size={14} strokeWidth={2} aria-hidden />
        </button>
      ) : null}
    </div>
    </div>
  );
}

export function NewsBlockList({
  blocks,
  media,
  readOnly,
  actionsDisabled,
  documentMode = false,
  uploadingBlockKind,
  uploadValidationErrors,
  onChange,
  onUploadForBlock,
  onUploadForGallerySlot,
  uploadingGallerySlot = null,
  blockUploadPreview = null,
}: NewsBlockListProps) {
  const t = useTranslations('news');
  const { showToast } = useToast();
  const [activeId, setActiveId] = useState<string | null>(null);
  const [overlayWidth, setOverlayWidth] = useState<number | undefined>();
  const [overlayHeight, setOverlayHeight] = useState<number | undefined>();
  const pendingActivationOffset = useRef<{ x: number; y: number } | null>(null);
  const [pendingDeleteIndex, setPendingDeleteIndex] = useState<number | null>(null);
  const announcements = useNewsBlockDragAnnouncements(blocks);

  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { delay: 120, tolerance: 5 } }),
    useSensor(TouchSensor, { activationConstraint: { delay: 180, tolerance: 6 } }),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates }),
  );

  const atBlockLimit = blocks.length >= MAX_BODY_BLOCKS;
  const ids = blocks.map((b, i) => b.id ?? `block-${i}`);
  const activeIndex = activeId ? ids.indexOf(activeId) : -1;
  const activeBlock = activeIndex >= 0 ? blocks[activeIndex] : null;
  const pendingBlock = pendingDeleteIndex !== null ? blocks[pendingDeleteIndex] : null;

  const resolveIndex = useCallback(
    (id: string | number) => ids.indexOf(String(id)),
    [ids],
  );

  function handleBlockLimit() {
    showToast({
      tone: 'warning',
      title: t('toast.validationTitle'),
      message: t('validation.blockLimit'),
    });
  }

  function updateBlock(index: number, block: NewsBodyBlock) {
    const next = [...blocks];
    next[index] = block;
    onChange(next);
  }

  function removeBlock(index: number) {
    onChange(blocks.filter((_, i) => i !== index));
  }

  function handleInsert(index: number, block: NewsBodyBlock) {
    onChange(insertBlockIntoBody(blocks, index, block));
  }

  function handleDragPending(event: DragPendingEvent) {
    if (event.offset) {
      pendingActivationOffset.current = event.offset;
    }
  }

  function handleDragStart(event: DragStartEvent) {
    setActiveId(String(event.active.id));
    const rect = event.active.rect.current.initial;
    const activator = getEventCoordinates(event.activatorEvent);
    const activationDeltaY = pendingActivationOffset.current?.y ?? 0;
    if (rect && activator) {
      setOverlayWidth(rect.width);
      setOverlayHeight(rect.height);
      setBlockDragPickupContext({
        activeTop: rect.top,
        pickupOffsetY: activator.y + activationDeltaY - rect.top,
        activationDeltaY,
      });
    }
    pendingActivationOffset.current = null;
  }

  function handleDragEnd(event: DragEndEvent) {
    setActiveId(null);
    setOverlayWidth(undefined);
    setOverlayHeight(undefined);
    setBlockDragPickupContext(null);
    const { active, over } = event;
    if (!over || active.id === over.id) return;
    const oldIndex = resolveIndex(active.id);
    const newIndex = resolveIndex(over.id);
    if (oldIndex < 0 || newIndex < 0) return;
    onChange(arrayMove(blocks, oldIndex, newIndex));
  }

  function handleDragCancel() {
    setActiveId(null);
    setOverlayWidth(undefined);
    setOverlayHeight(undefined);
    setBlockDragPickupContext(null);
    pendingActivationOffset.current = null;
  }

  const dropAnimation = {
    duration: 220,
    easing: 'cubic-bezier(0.2, 0.8, 0.2, 1)',
    sideEffects: defaultDropAnimationSideEffects({
      styles: { active: { opacity: '0.5' } },
    }),
  };

  const dragOverlayModifiers = [
    snapBlockOverlayToPickup,
    restrictToVerticalAxis,
    restrictToWindowEdges,
  ];

  return (
    <div className={styles.root} data-dragging-active={activeId ? 'true' : undefined}>
      {!documentMode && !activeId ? (
        <NewsBlockInserter
          index={0}
          readOnly={readOnly}
          atBlockLimit={atBlockLimit}
          prominent={blocks.length === 0}
          onInsert={handleInsert}
          onBlockLimit={handleBlockLimit}
        />
      ) : null}
      <DndContext
        sensors={sensors}
        collisionDetection={newsBlockCollisionDetection}
        measuring={{
          droppable: {
            strategy: MeasuringStrategy.Always,
          },
        }}
        autoScroll={{
          threshold: { x: 0, y: 0.15 },
          acceleration: 8,
          interval: 5,
        }}
        modifiers={[restrictToVerticalAxis]}
        accessibility={{ announcements }}
        onDragPending={handleDragPending}
        onDragStart={handleDragStart}
        onDragEnd={handleDragEnd}
        onDragCancel={handleDragCancel}
      >
        <SortableContext items={ids} strategy={verticalListSortingStrategy}>
          {blocks.map((block, index) => (
            <div key={ids[index]}>
              <SortableBlockRow
                sortableId={ids[index]}
                sortableIds={ids}
                block={block}
                index={index}
                total={blocks.length}
                media={media}
                readOnly={readOnly}
                actionsDisabled={actionsDisabled}
                activeIndex={activeIndex}
                documentMode={documentMode}
                uploadingBlockKind={uploadingBlockKind}
                uploadValidationErrors={uploadValidationErrors}
                uploadingGallerySlot={uploadingGallerySlot}
                blockUploadPreview={blockUploadPreview}
                onChange={(next) => updateBlock(index, next)}
                onRequestRemove={() => setPendingDeleteIndex(index)}
                {...(onUploadForBlock
                  ? {
                      onUploadForBlock: (file: File) =>
                        onUploadForBlock(index, file, block.type === 'video' ? 'video' : 'image'),
                    }
                  : {})}
                {...(onUploadForGallerySlot
                  ? {
                      onUploadForGallerySlot: (itemIndex: number, file: File) =>
                        onUploadForGallerySlot(index, itemIndex, file),
                    }
                  : {})}
              />
              {!documentMode && !activeId ? (
                <NewsBlockInserter
                  index={index + 1}
                  readOnly={readOnly}
                  atBlockLimit={atBlockLimit}
                  onInsert={handleInsert}
                  onBlockLimit={handleBlockLimit}
                />
              ) : null}
            </div>
          ))}
        </SortableContext>
        <NewsBlockDragOverlayPortal>
          <DragOverlay
            adjustScale={false}
            dropAnimation={dropAnimation}
            modifiers={dragOverlayModifiers}
            className={styles.dragOverlay}
            zIndex={10000}
          >
            {activeBlock && activeIndex >= 0 ? (
              <NewsBlockDragOverlayRow
                block={activeBlock}
                media={media}
                documentMode={documentMode}
                width={overlayWidth}
                height={overlayHeight}
              />
            ) : null}
          </DragOverlay>
        </NewsBlockDragOverlayPortal>
      </DndContext>
      {blocks.length === 0 && !readOnly && documentMode ? (
        <NewsBlockInsertStarter
          disabled={actionsDisabled || atBlockLimit}
          onInsert={(type) => {
            if (atBlockLimit) {
              handleBlockLimit();
              return;
            }
            onChange(insertBlockIntoBody(blocks, 0, createBlockFromType(type)));
          }}
        />
      ) : blocks.length === 0 && !readOnly ? (
        <p className={styles.emptyHint}>{t('form.emptyBodyHint')}</p>
      ) : null}

      <NewsBlockRemoveDialog
        open={pendingDeleteIndex !== null && pendingBlock !== null}
        block={pendingBlock}
        index={pendingDeleteIndex ?? 0}
        total={blocks.length}
        media={media}
        onConfirm={() => {
          if (pendingDeleteIndex === null) return;
          removeBlock(pendingDeleteIndex);
          setPendingDeleteIndex(null);
        }}
        onClose={() => setPendingDeleteIndex(null)}
      />
    </div>
  );
}
