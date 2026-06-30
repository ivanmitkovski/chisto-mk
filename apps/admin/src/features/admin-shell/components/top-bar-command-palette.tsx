'use client';

import { KeyboardEvent as ReactKeyboardEvent, RefObject, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { useTranslations } from 'next-intl';
import { Icon, Input } from '@/components/ui';
import { useFocusTrap } from '@/lib/utils';
import { useOverlayAnimation } from '@/lib/utils/use-overlay-animation';
import type { GroupedCommands } from '../commands/use-command-registry';
import type { CommandGroup, ResolvedCommand, ScoredCommand } from '../commands/types';
import styles from './top-bar-command-palette.module.css';

type TopBarCommandPaletteProps = {
  open: boolean;
  portalReady: boolean;
  shortcutLabel: string;
  query: string;
  activeIndex: number;
  flatResults: ScoredCommand[];
  groupedResults: GroupedCommands[];
  activeItem: ScoredCommand | null;
  entityLoading: boolean;
  entityErrors: Partial<Record<'users' | 'reports' | 'sites', string>>;
  resultCount: number;
  palettePanelRef: RefObject<HTMLDivElement | null>;
  paletteInputRef: RefObject<HTMLInputElement | null>;
  onQueryChange: (event: React.ChangeEvent<HTMLInputElement>) => void;
  onMoveSelection: (step: 1 | -1) => void;
  onMoveToBoundary: (target: 'start' | 'end') => void;
  onSelectIndex: (index: number) => void;
  onExecuteCommand: (command: ResolvedCommand) => void;
  onClosePalette: () => void;
};

function HighlightedLabel({
  label,
  match,
}: {
  label: string;
  match?: { start: number; end: number };
}) {
  if (!match) {
    return <strong>{label}</strong>;
  }
  return (
    <strong>
      {label.slice(0, match.start)}
      <mark className={styles.mark}>{label.slice(match.start, match.end)}</mark>
      {label.slice(match.end)}
    </strong>
  );
}

function FooterHint({ label, keys }: { label: string; keys: string[] }) {
  return (
    <span className={styles.footerHint}>
      {keys.map((key) => (
        <kbd key={key} className={styles.kbd}>
          {key}
        </kbd>
      ))}
      <span className={styles.footerHintLabel}>{label}</span>
    </span>
  );
}

function CommandLoadingSkeleton() {
  return (
    <div className={styles.loadingRows} aria-busy="true" aria-hidden="true">
      {[0, 1, 2].map((index) => (
        <div key={index} className={styles.skeletonRow}>
          <span className={styles.skeletonIcon} />
          <span className={styles.skeletonText}>
            <span className={styles.skeletonLine} />
            <span className={styles.skeletonLineShort} />
          </span>
        </div>
      ))}
    </div>
  );
}

function groupLabelKey(group: CommandGroup): string {
  return `groups.${group}`;
}

export function TopBarCommandPalette({
  open,
  portalReady,
  shortcutLabel,
  query,
  activeIndex,
  flatResults,
  groupedResults,
  activeItem,
  entityLoading,
  entityErrors,
  resultCount,
  palettePanelRef,
  paletteInputRef,
  onQueryChange,
  onMoveSelection,
  onMoveToBoundary,
  onSelectIndex,
  onExecuteCommand,
  onClosePalette,
}: TopBarCommandPaletteProps) {
  const t = useTranslations('common');
  const tPalette = useTranslations('commandPalette');
  const { mounted, phase, finishExit } = useOverlayAnimation(open);
  const listRef = useRef<HTMLDivElement>(null);
  const activeOptionRef = useRef<HTMLButtonElement | null>(null);
  const pointerMovedRef = useRef(false);
  const keyboardNavRef = useRef(false);

  useFocusTrap(mounted && phase !== 'exit', palettePanelRef);

  useEffect(() => {
    if (!open) {
      pointerMovedRef.current = false;
      keyboardNavRef.current = false;
    }
  }, [open]);

  useEffect(() => {
    if (!open || !mounted || phase === 'exit') return;
    const resetScroll = () => listRef.current?.scrollTo({ top: 0 });
    resetScroll();
    const frame = requestAnimationFrame(resetScroll);
    return () => cancelAnimationFrame(frame);
  }, [open, mounted, phase, query, resultCount]);

  useEffect(() => {
    if (!mounted || phase === 'exit') return undefined;
    const previous = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = previous;
    };
  }, [mounted, phase]);

  useEffect(() => {
    if (!mounted || phase === 'exit') return;
    const timeoutId = window.setTimeout(() => paletteInputRef.current?.focus(), 0);
    return () => window.clearTimeout(timeoutId);
  }, [mounted, paletteInputRef, phase]);

  useEffect(() => {
    if (!keyboardNavRef.current) return;
    activeOptionRef.current?.scrollIntoView({ block: 'nearest' });
    keyboardNavRef.current = false;
  }, [activeIndex, activeItem?.command.id]);

  function onPaletteInputKeyDown(event: ReactKeyboardEvent<HTMLInputElement>) {
    if (event.key === 'ArrowDown') {
      event.preventDefault();
      keyboardNavRef.current = true;
      onMoveSelection(1);
      return;
    }
    if (event.key === 'ArrowUp') {
      event.preventDefault();
      keyboardNavRef.current = true;
      onMoveSelection(-1);
      return;
    }
    if (event.key === 'Home') {
      event.preventDefault();
      keyboardNavRef.current = true;
      onMoveToBoundary('start');
      return;
    }
    if (event.key === 'End') {
      event.preventDefault();
      keyboardNavRef.current = true;
      onMoveToBoundary('end');
      return;
    }
    if (event.key === 'Enter' && activeItem) {
      event.preventDefault();
      onExecuteCommand(activeItem.command);
      return;
    }
    if (event.key === 'Escape') {
      event.preventDefault();
      onClosePalette();
    }
  }

  function handlePanelAnimationEnd(event: React.AnimationEvent<HTMLElement>) {
    if (phase !== 'exit' || event.target !== palettePanelRef.current) return;
    finishExit();
  }

  function handlePointerMove() {
    pointerMovedRef.current = true;
  }

  function handleItemMouseEnter(index: number) {
    if (!pointerMovedRef.current) return;
    onSelectIndex(index);
  }

  if (!portalReady || !mounted || typeof document === 'undefined') {
    return null;
  }

  let runningIndex = -1;

  return createPortal(
    <div className={styles.paletteBackdrop} data-state={phase}>
      <button type="button" className={styles.scrim} aria-label={t('closeDialog')} onClick={onClosePalette} />
      <section
        ref={palettePanelRef}
        className={styles.palette}
        data-command-palette-panel=""
        role="dialog"
        aria-modal="true"
        aria-label={t('commandPalette')}
        data-state={phase}
        onAnimationEnd={handlePanelAnimationEnd}
      >
        <div className={styles.paletteChrome}>
          <div className={styles.paletteSearchWrap}>
            <Input
              inputRef={paletteInputRef}
              aria-label={t('searchCommands')}
              role="combobox"
              aria-expanded
              aria-controls="command-palette-list"
              aria-autocomplete="list"
              aria-activedescendant={activeItem ? `command-option-${activeItem.command.id}` : undefined}
              placeholder={t('typeCommandOrRoute')}
              value={query}
              onChange={onQueryChange}
              onKeyDown={onPaletteInputKeyDown}
              className={styles.paletteSearch}
              leftSlot={<Icon name="magnifying-glass" size={16} />}
            />
          </div>
        </div>

        <div
          ref={listRef}
          className={styles.paletteBody}
          onPointerMove={handlePointerMove}
        >
          <p className={styles.listMeta} aria-live="polite" aria-atomic="true">
            {tPalette('resultCount', { count: resultCount })}
          </p>

          <div
            id="command-palette-list"
            role="listbox"
            className={styles.commandList}
            aria-label={t('availableCommands')}
          >
          {groupedResults.map((section) => (
            <div key={section.group} className={styles.groupBlock} role="group" aria-label={tPalette(groupLabelKey(section.group))}>
              <p className={styles.groupLabel}>{tPalette(groupLabelKey(section.group))}</p>
              <div className={styles.groupList}>
                {section.items.map((item) => {
                  runningIndex += 1;
                  const index = runningIndex;
                  const isActive = index === activeIndex;
                  return (
                    <button
                      key={item.command.id}
                      ref={isActive ? activeOptionRef : null}
                      type="button"
                      role="option"
                      id={`command-option-${item.command.id}`}
                      aria-selected={isActive}
                      className={`${styles.commandItem} ${isActive ? styles.commandItemActive : ''}`}
                      onMouseEnter={() => handleItemMouseEnter(index)}
                      onClick={() => onExecuteCommand(item.command)}
                    >
                      <span className={styles.commandIcon}>
                        <Icon name={item.command.icon} size={14} />
                      </span>
                      <span className={styles.commandText}>
                        <HighlightedLabel label={item.command.label} {...(item.labelMatch ? { match: item.labelMatch } : {})} />
                        {item.command.description ? <small>{item.command.description}</small> : null}
                      </span>
                      {item.command.href ? (
                        <span className={styles.commandHint}>{item.command.href}</span>
                      ) : null}
                    </button>
                  );
                })}
              </div>
            </div>
          ))}

          </div>

          {entityLoading ? <CommandLoadingSkeleton /> : null}

          {Object.keys(entityErrors).length > 0 ? (
            <div className={styles.errorRow} role="alert">
              {tPalette('entitySearchFailed')}
            </div>
          ) : null}

          {flatResults.length === 0 && !entityLoading ? (
            <div className={styles.emptyResults} role="status">
              <Icon name="magnifying-glass" size={20} className={styles.emptyIcon} />
              <p>{t('noCommandsMatchQuery')}</p>
            </div>
          ) : null}
        </div>

        <footer className={styles.footer}>
          <FooterHint label={tPalette('footerNavigateLabel')} keys={['↑', '↓']} />
          <FooterHint label={tPalette('footerSelectLabel')} keys={['↵']} />
          <FooterHint label={tPalette('footerCloseLabel')} keys={['esc']} />
          <span className={styles.footerHint}>
            <kbd className={styles.kbd}>{shortcutLabel}</kbd>
            <span className={styles.footerHintLabel}>{tPalette('footerToggleLabel')}</span>
          </span>
        </footer>
      </section>
    </div>,
    document.body,
  );
}
