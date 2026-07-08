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
import {
  clipboardToNewsBlocks,
  isBodyEmptyOrSkeleton,
  type ClipboardImportResult,
} from '@chisto/news-content';
import { useCallback, useEffect, useMemo, useRef, useState, memo } from 'react';
import { Icon, useToast } from '@/components/ui';
import type { NewsBodyBlock, NewsMediaDto } from '../news-api-types';
import { useNewsBlockDragAnnouncements } from '../hooks/use-news-block-drag-announcements';
import { newsBlockCollisionDetection } from '../lib/news-block-drag-collision';
import { resolveBlockDropEdge } from '../lib/news-block-drop-edge';
import {
  setBlockDragPickupContext,
  snapBlockOverlayToPickup,
} from '../lib/news-block-drag-overlay-modifiers';
import {
  createBlockFromType,
  type BlockInsertType,
} from '../lib/news-block-insert-config';
import {
  duplicateBlockAt,
  insertImportedBlocksAt,
  isTransformableBlock,
  mergeParagraphWithPrevious,
  paragraphBlocksFromPlainText,
  removeBlockAt,
  replaceBlockAt,
  replaceBlockWithMany,
  restoreBlockAt,
  splitHtmlIntoParagraphBlocks,
  transformBlockAt,
  type TransformTarget,
} from '../lib/news-block-operations';
import { isStructuredImport, readClipboardForImport, type ClipboardImportPayload } from '../lib/news-structured-paste';
import { recordBlockInsertRecent } from '../lib/news-block-insert-recents';
import {
  buildSlashInsertSections,
  templateBlocksForSlash,
} from '../lib/news-block-slash-sections';
import { MAX_BODY_BLOCKS } from '../lib/news-post-policy';
import { insertBlockIntoBody, NewsBlockInserter } from './news-block-inserter';
import {
  NewsBlockInsertMenuPanel,
  type NewsBlockInsertMenuSection,
} from './news-block-insert-menu';
import { NewsBlockInsertStarter } from './news-block-insert-starter';
import { NewsBlockDragOverlayRow } from './news-block-drag-overlay-row';
import { NewsBlockDragOverlayPortal } from './news-block-drag-overlay-portal';
import { NewsBlockRemoveDialog } from './news-block-remove-dialog';
import { NewsPasteConfirmDialog } from './news-paste-confirm-dialog';
import { NewsBlockTransformMenu } from './news-block-transform-menu';
import { NewsBodyBlockEditor } from './news-body-block-editor';
import type { NewsFormLocale } from '../types';
import styles from './news-block-list.module.css';

type NewsBlockListProps = {
  blocks: NewsBodyBlock[];
  locale: string;
  media: NewsMediaDto[];
  readOnly: boolean;
  actionsDisabled: boolean;
  uploadingBlockKind?: 'inline_image' | 'inline_video' | null;
  uploadValidationErrors?: Partial<Record<'inline_image' | 'inline_video', string>>;
  onChange: (blocks: NewsBodyBlock[]) => void;
  onUploadForBlock?: (blockIndex: number, file: File, blockType: 'image' | 'video') => void;
  onUploadForGallerySlot?: (blockIndex: number, itemIndex: number, file: File) => void;
  onPasteImageAt?: (insertIndex: number, file: File) => void;
  pasteBodyRef?: React.RefObject<((raw: ClipboardImportPayload | null) => Promise<void>) | null>;
  uploadingGallerySlot?: { blockIndex: number; itemIndex: number } | null | undefined;
  blockUploadPreview?: { blockIndex: number; url: string } | null | undefined;
};

type SortableRowProps = {
  sortableId: string;
  sortableIds: string[];
  block: NewsBodyBlock;
  index: number;
  media: NewsMediaDto[];
  readOnly: boolean;
  actionsDisabled: boolean;
  activeIndex: number;
  uploadingBlockKind?: 'inline_image' | 'inline_video' | null | undefined;
  uploadValidationErrors?: Partial<Record<'inline_image' | 'inline_video', string>> | undefined;
  uploadingGallerySlot?: { blockIndex: number; itemIndex: number } | null | undefined;
  blockUploadPreview?: { blockIndex: number; url: string } | null | undefined;
  autoFocus: boolean;
  slashOpen: boolean;
  slashFilter: string;
  onSlashFilterChange: (query: string) => void;
  onAutoFocused: () => void;
  onSlashMenu: () => void;
  onSlashClose: () => void;
  onSlashSelect: (type: BlockInsertType) => void;
  onSlashTemplate: (templateId: Exclude<import('../lib/news-content-templates').NewsContentTemplateId, 'blank'>) => void;
  onInsertParagraphAfter: () => void;
  onCreateBlockAfter: () => void;
  onMergeWithPrevious: () => void;
  onMultiParagraphPaste: (raw: { html: string; plain: string }) => boolean;
  onPasteImageFile: (file: File) => boolean;
  onChange: (block: NewsBodyBlock) => void;
  onRequestRemove: () => void;
  onDuplicate: () => void;
  onTransform: (target: TransformTarget) => void;
  onUploadForBlock?: ((file: File) => void) | undefined;
  onUploadForGallerySlot?: ((itemIndex: number, file: File) => void) | undefined;
};

function SortableBlockRowInner({
  sortableId,
  sortableIds,
  block,
  index,
  media,
  readOnly,
  actionsDisabled,
  activeIndex,
  uploadingBlockKind,
  uploadValidationErrors,
  uploadingGallerySlot,
  blockUploadPreview,
  autoFocus,
  slashOpen,
  slashFilter,
  onSlashFilterChange,
  onAutoFocused,
  onSlashMenu,
  onSlashClose,
  onSlashSelect,
  onSlashTemplate,
  onInsertParagraphAfter,
  onCreateBlockAfter,
  onMergeWithPrevious,
  onMultiParagraphPaste,
  onPasteImageFile,
  onChange,
  onRequestRemove,
  onDuplicate,
  onTransform,
  onUploadForBlock,
  onUploadForGallerySlot,
}: SortableRowProps) {
  const slashPanelRef = useRef<HTMLDivElement>(null);
  const slashAnchorRef = useRef<HTMLDivElement>(null);
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
    if (!slashOpen) return;
    function onDocClick(event: MouseEvent) {
      if (!slashAnchorRef.current?.contains(event.target as Node)) onSlashClose();
    }
    document.addEventListener('mousedown', onDocClick);
    return () => document.removeEventListener('mousedown', onDocClick);
  }, [onSlashClose, slashOpen]);

  const slashSections = useMemo<NewsBlockInsertMenuSection[]>(
    () =>
      buildSlashInsertSections({
        t,
        filter: slashFilter,
        onSelect: onSlashSelect,
        onTemplate: onSlashTemplate,
      }),
    [onSlashSelect, onSlashTemplate, slashFilter, t],
  );

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

  const rowClass = [styles.row, styles.rowDocument, isDragging ? styles.rowDragging : '']
    .filter(Boolean)
    .join(' ');
  const wrapClass = [
    styles.rowWrap,
    styles.rowWrapDocument,
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
      data-block-type={block.type}
    >
    <div className={rowClass}>
      {!readOnly ? (
        <button
          ref={setActivatorNodeRef}
          type="button"
          className={styles.dragHandleDocument}
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
          media={media}
          readOnly={readOnly}
          busy={actionsDisabled}
          uploadBusy={blockUploadBusy}
          uploadError={uploadError}
          localPreviewSrc={
            blockUploadPreview?.blockIndex === index ? blockUploadPreview.url : null
          }
          autoFocus={autoFocus}
          onAutoFocused={onAutoFocused}
          onInsertParagraphAfter={onInsertParagraphAfter}
          onCreateBlockAfter={onCreateBlockAfter}
          onMergeWithPrevious={onMergeWithPrevious}
          onMultiParagraphPaste={onMultiParagraphPaste}
          onPasteImageFile={onPasteImageFile}
          onRemoveSelf={onRequestRemove}
          onSlashMenu={onSlashMenu}
          onChange={onChange}
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
        <div ref={slashAnchorRef} className={styles.slashMenuAnchor}>
          <NewsBlockInsertMenuPanel
            open={slashOpen}
            sections={slashSections}
            ariaLabel={t('form.insertBlock')}
            panelRef={slashPanelRef}
            filterQuery={slashFilter}
            filterPlaceholder={t('insert.filterPlaceholder')}
            emptyLabel={t('insert.filterEmpty')}
            onFilterChange={onSlashFilterChange}
            onClose={onSlashClose}
          />
        </div>
      </div>
      {!readOnly ? (
        <div className={styles.rowActions}>
          <NewsBlockTransformMenu
            block={block}
            disabled={actionsDisabled}
            buttonClassName={styles.rowActionBtn}
            onTransform={onTransform}
          />
          <button
            type="button"
            className={styles.rowActionBtn}
            disabled={actionsDisabled}
            onClick={onDuplicate}
            aria-label={t('form.duplicateBlock')}
            title={t('form.duplicateBlock')}
          >
            <Icon name="copy" size={14} strokeWidth={2} aria-hidden />
          </button>
          <button
            type="button"
            className={styles.removeBtnDocument}
            disabled={actionsDisabled}
            onClick={onRequestRemove}
            aria-label={t('form.removeBlock')}
            title={t('form.removeBlock')}
          >
            <Icon name="x" size={14} strokeWidth={2} aria-hidden />
          </button>
        </div>
      ) : null}
    </div>
    </div>
  );
}

const SortableBlockRow = memo(SortableBlockRowInner);

export function NewsBlockList({
  blocks,
  locale,
  media,
  readOnly,
  actionsDisabled,
  uploadingBlockKind,
  uploadValidationErrors,
  onChange,
  onUploadForBlock,
  onUploadForGallerySlot,
  onPasteImageAt,
  pasteBodyRef,
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
  const [pendingPaste, setPendingPaste] = useState<{
    result: ClipboardImportResult;
    index: number;
  } | null>(null);
  const announcements = useNewsBlockDragAnnouncements(blocks);
  const blocksRef = useRef(blocks);
  blocksRef.current = blocks;
  const [focusBlockId, setFocusBlockId] = useState<string | null>(null);
  const [slashIndex, setSlashIndex] = useState<number | null>(null);
  const [slashFilter, setSlashFilter] = useState('');

  useEffect(() => {
    if (slashIndex === null) setSlashFilter('');
  }, [slashIndex]);

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
    onChange(removeBlockAt(blocks, index));
  }

  /** Text blocks delete instantly with a 5s Undo; media and advanced blocks keep the confirm dialog. */
  function requestRemove(index: number) {
    const block = blocks[index];
    if (!block) return;
    if (isTransformableBlock(block)) {
      onChange(removeBlockAt(blocks, index));
      showToast({
        tone: 'info',
        title: t('toast.blockDeleted'),
        message: '',
        durationMs: 5000,
        action: {
          label: t('toast.undo'),
          onAction: () => onChange(restoreBlockAt(blocksRef.current, index, block)),
        },
      });
      return;
    }
    setPendingDeleteIndex(index);
  }

  function handleDuplicate(index: number) {
    if (atBlockLimit) {
      handleBlockLimit();
      return;
    }
    onChange(duplicateBlockAt(blocks, index));
  }

  function handleTransform(index: number, target: TransformTarget) {
    onChange(transformBlockAt(blocks, index, target));
  }

  function handleInsertParagraphAfter(index: number) {
    if (atBlockLimit) {
      handleBlockLimit();
      return;
    }
    const paragraph = createBlockFromType('paragraph');
    onChange(insertBlockIntoBody(blocks, index + 1, paragraph));
    setFocusBlockId(paragraph.id ?? null);
  }

  function handleMergeWithPrevious(index: number) {
    if (index <= 0) return;
    const prev = blocks[index - 1];
    const current = blocks[index];
    if (!prev || !current || prev.type !== 'paragraph' || current.type !== 'paragraph') {
      if (current?.type === 'paragraph' && !current.text.trim() && !current.html?.trim()) {
        onChange(removeBlockAt(blocks, index));
      }
      return;
    }
    onChange(mergeParagraphWithPrevious(blocks, index));
    if (prev.id) setFocusBlockId(prev.id);
  }

  function showPasteUndo(snapshot: NewsBodyBlock[]) {
    showToast({
      tone: 'info',
      title: t('paste.appliedTitle'),
      message: '',
      durationMs: 5000,
      action: {
        label: t('toast.undo'),
        onAction: () => onChange(snapshot),
      },
    });
  }

  function applyImportedBlocks(
    replacements: NewsBodyBlock[],
    index: number,
    mode: 'replace' | 'insert',
  ) {
    const snapshot = blocksRef.current;
    if (mode === 'replace') {
      const capped = replacements.slice(0, MAX_BODY_BLOCKS);
      onChange(capped);
      const last = capped[capped.length - 1];
      if (last?.id) setFocusBlockId(last.id);
      showPasteUndo(snapshot);
      return;
    }

    if (atBlockLimit) {
      handleBlockLimit();
      return;
    }

    const available = MAX_BODY_BLOCKS - snapshot.length + 1;
    const capped = replacements.slice(0, Math.max(1, available));
    const next = insertImportedBlocksAt(snapshot, index, capped);
    onChange(next);
    const last = capped[capped.length - 1];
    if (last?.id) setFocusBlockId(last.id);
    showPasteUndo(snapshot);
  }

  function offerStructuredPaste(result: ClipboardImportResult, index: number) {
    if (isBodyEmptyOrSkeleton(blocksRef.current)) {
      applyImportedBlocks(result.blocks, index, 'replace');
      if (result.truncated) {
        showToast({
          tone: 'warning',
          title: t('toast.validationTitle'),
          message: t('paste.truncatedWarning'),
        });
      }
      return;
    }
    setPendingPaste({ result, index });
  }

  function handleStructuredPaste(
    index: number,
    raw: { html: string; plain: string },
  ): boolean {
    const current = blocks[index];
    if (!current || current.type !== 'paragraph') return false;
    if (current.text.trim() || current.html?.trim()) return false;

    const imported = clipboardToNewsBlocks(raw, { maxBlocks: MAX_BODY_BLOCKS });
    if (imported && isStructuredImport(imported.blocks)) {
      offerStructuredPaste(imported, index);
      return true;
    }

    let replacements = raw.html ? splitHtmlIntoParagraphBlocks(raw.html) : [];
    if (replacements.length <= 1 && raw.plain.includes('\n')) {
      replacements = paragraphBlocksFromPlainText(raw.plain);
    }
    if (replacements.length <= 1) return false;

    onChange(replaceBlockWithMany(blocks, index, replacements));
    const last = replacements[replacements.length - 1];
    setFocusBlockId(last?.id ?? null);
    return true;
  }

  const pasteBodyFromClipboard = useCallback(async (raw: ClipboardImportPayload | null = null) => {
    if (readOnly || actionsDisabled) return;

    const clipboard = raw ?? (await readClipboardForImport());
    if (!clipboard) {
      showToast({
        tone: 'warning',
        title: t('toast.validationTitle'),
        message: t('paste.clipboardUnavailable'),
      });
      return;
    }

    const imported = clipboardToNewsBlocks(clipboard, { maxBlocks: MAX_BODY_BLOCKS });
    if (!imported || !isStructuredImport(imported.blocks)) {
      showToast({
        tone: 'warning',
        title: t('toast.validationTitle'),
        message: t('paste.unstructuredWarning'),
      });
      return;
    }
    const index = Math.max(0, blocksRef.current.length - 1);
    offerStructuredPaste(imported, index);
  }, [actionsDisabled, readOnly, t, showToast]);

  useEffect(() => {
    if (!pasteBodyRef) return;
    pasteBodyRef.current = pasteBodyFromClipboard;
    return () => {
      pasteBodyRef.current = null;
    };
  }, [pasteBodyFromClipboard, pasteBodyRef]);

  function handlePasteImageFile(index: number, file: File): boolean {
    if (!onPasteImageAt) return false;
    if (atBlockLimit) {
      handleBlockLimit();
      return true;
    }
    onPasteImageAt(index + 1, file);
    return true;
  }

  function handleSlashSelect(index: number, type: BlockInsertType) {
    setSlashIndex(null);
    setSlashFilter('');
    recordBlockInsertRecent(type);
    const block = createBlockFromType(type);
    onChange(replaceBlockAt(blocksRef.current, index, block));
    if (block.type === 'heading' || block.type === 'paragraph' || block.type === 'list' || block.type === 'quote' || block.type === 'embed') {
      setFocusBlockId(block.id ?? null);
    }
  }

  function handleSlashTemplate(
    index: number,
    templateId: Exclude<import('../lib/news-content-templates').NewsContentTemplateId, 'blank'>,
  ) {
    setSlashIndex(null);
    setSlashFilter('');
    const templateBlocks = templateBlocksForSlash(templateId, locale as NewsFormLocale);
    if (templateBlocks.length === 0) return;
    const available = MAX_BODY_BLOCKS - blocks.length + 1;
    const replacements = templateBlocks.slice(0, Math.max(1, available));
    onChange(replaceBlockWithMany(blocksRef.current, index, replacements));
    const last = replacements[replacements.length - 1];
    setFocusBlockId(last?.id ?? null);
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
                media={media}
                readOnly={readOnly}
                actionsDisabled={actionsDisabled}
                activeIndex={activeIndex}
                uploadingBlockKind={uploadingBlockKind}
                uploadValidationErrors={uploadValidationErrors}
                uploadingGallerySlot={uploadingGallerySlot}
                blockUploadPreview={blockUploadPreview}
                autoFocus={focusBlockId !== null && ids[index] === focusBlockId}
                slashOpen={slashIndex === index}
                slashFilter={slashFilter}
                onSlashFilterChange={setSlashFilter}
                onAutoFocused={() => setFocusBlockId(null)}
                onSlashMenu={() => setSlashIndex(index)}
                onSlashClose={() => setSlashIndex(null)}
                onSlashSelect={(type) => handleSlashSelect(index, type)}
                onSlashTemplate={(templateId) => handleSlashTemplate(index, templateId)}
                onInsertParagraphAfter={() => handleInsertParagraphAfter(index)}
                onCreateBlockAfter={() => handleInsertParagraphAfter(index)}
                onMergeWithPrevious={() => handleMergeWithPrevious(index)}
                onMultiParagraphPaste={(raw) => handleStructuredPaste(index, raw)}
                onPasteImageFile={(file) => handlePasteImageFile(index, file)}
                onChange={(next) => updateBlock(index, next)}
                onRequestRemove={() => requestRemove(index)}
                onDuplicate={() => handleDuplicate(index)}
                onTransform={(target) => handleTransform(index, target)}
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
              {!activeId ? (
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
                width={overlayWidth}
                height={overlayHeight}
              />
            ) : null}
          </DragOverlay>
        </NewsBlockDragOverlayPortal>
      </DndContext>
      {blocks.length === 0 && !readOnly ? (
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

      <NewsPasteConfirmDialog
        open={pendingPaste !== null}
        result={pendingPaste?.result ?? null}
        onClose={() => setPendingPaste(null)}
        onReplace={() => {
          if (!pendingPaste) return;
          applyImportedBlocks(pendingPaste.result.blocks, pendingPaste.index, 'replace');
          if (pendingPaste.result.truncated) {
            showToast({
              tone: 'warning',
              title: t('toast.validationTitle'),
              message: t('paste.truncatedWarning'),
            });
          }
          setPendingPaste(null);
        }}
        onInsert={() => {
          if (!pendingPaste) return;
          applyImportedBlocks(pendingPaste.result.blocks, pendingPaste.index, 'insert');
          if (pendingPaste.result.truncated) {
            showToast({
              tone: 'warning',
              title: t('toast.validationTitle'),
              message: t('paste.truncatedWarning'),
            });
          }
          setPendingPaste(null);
        }}
      />
    </div>
  );
}
