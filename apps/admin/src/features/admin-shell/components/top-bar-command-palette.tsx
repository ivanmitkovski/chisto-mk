'use client';

import { KeyboardEvent as ReactKeyboardEvent, RefObject } from 'react';
import { createPortal } from 'react-dom';
import { useTranslations } from 'next-intl';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import { Icon, Input } from '@/components/ui';
import type { TopBarCommand } from '../types/top-bar';
import styles from './top-bar-command-palette.module.css';

type TopBarCommandPaletteProps = {
  isOpen: boolean;
  portalReady: boolean;
  query: string;
  activeIndex: number;
  filteredCommands: ReadonlyArray<TopBarCommand>;
  activeCommand: TopBarCommand | null;
  palettePanelRef: RefObject<HTMLDivElement | null>;
  paletteInputRef: RefObject<HTMLInputElement | null>;
  onQueryChange: (event: React.ChangeEvent<HTMLInputElement>) => void;
  onMoveSelection: (step: 1 | -1) => void;
  onMoveToBoundary: (target: 'start' | 'end') => void;
  onSelectIndex: (index: number) => void;
  onExecuteCommand: (command: TopBarCommand) => void;
  onClosePalette: () => void;
};

export function TopBarCommandPalette({
  isOpen,
  portalReady,
  query,
  activeIndex,
  filteredCommands,
  activeCommand,
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
  const reduceMotion = useReducedMotion();

  function onPaletteInputKeyDown(event: ReactKeyboardEvent<HTMLInputElement>) {
    if (event.key === 'ArrowDown') {
      event.preventDefault();
      onMoveSelection(1);
      return;
    }

    if (event.key === 'ArrowUp') {
      event.preventDefault();
      onMoveSelection(-1);
      return;
    }

    if (event.key === 'Home') {
      event.preventDefault();
      onMoveToBoundary('start');
      return;
    }

    if (event.key === 'End') {
      event.preventDefault();
      onMoveToBoundary('end');
      return;
    }

    if (event.key === 'Enter' && activeCommand) {
      event.preventDefault();
      onExecuteCommand(activeCommand);
      return;
    }

    if (event.key === 'Escape') {
      event.preventDefault();
      onClosePalette();
    }
  }

  function onPaletteTrapKeyDown(event: ReactKeyboardEvent<HTMLDivElement>) {
    if (event.key !== 'Tab') {
      return;
    }

    const focusableElements = palettePanelRef.current?.querySelectorAll<HTMLElement>(
      'button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])',
    );

    if (!focusableElements || focusableElements.length === 0) {
      return;
    }

    const firstElement = focusableElements[0];
    const lastElement = focusableElements[focusableElements.length - 1];
    const activeElement = document.activeElement;

    if (!event.shiftKey && activeElement === lastElement) {
      event.preventDefault();
      firstElement.focus();
      return;
    }

    if (event.shiftKey && activeElement === firstElement) {
      event.preventDefault();
      lastElement.focus();
    }
  }

  if (!portalReady || typeof document === 'undefined') {
    return null;
  }

  return createPortal(
    <AnimatePresence>
      {isOpen ? (
        <motion.div
          className={styles.paletteBackdrop}
          initial={reduceMotion ? false : { opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: reduceMotion ? 0 : 0.16 }}
        >
          <motion.section
            ref={palettePanelRef}
            className={styles.palette}
            role="dialog"
            aria-modal="true"
            aria-label={t('commandPalette')}
            initial={reduceMotion ? false : { opacity: 0, y: 10, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={reduceMotion ? { opacity: 0 } : { opacity: 0, y: 6, scale: 0.98 }}
            transition={{ duration: reduceMotion ? 0 : 0.18, ease: 'easeOut' }}
            onKeyDown={onPaletteTrapKeyDown}
          >
            <div className={styles.paletteSearchWrap}>
              <Input
                inputRef={paletteInputRef}
                aria-label={t('searchCommands')}
                role="combobox"
                aria-expanded
                aria-controls="command-palette-list"
                aria-autocomplete="list"
                aria-activedescendant={activeCommand ? `command-option-${activeCommand.id}` : undefined}
                placeholder={t('typeCommandOrRoute')}
                value={query}
                onChange={onQueryChange}
                onKeyDown={onPaletteInputKeyDown}
                className={styles.paletteSearch}
                leftSlot={<Icon name="magnifying-glass" size={14} />}
              />
            </div>
            <ul id="command-palette-list" role="listbox" className={styles.commandList} aria-label={t('availableCommands')}>
              {filteredCommands.map((command, index) => (
                <li key={command.id}>
                  <button
                    type="button"
                    role="option"
                    id={`command-option-${command.id}`}
                    aria-selected={index === activeIndex}
                    className={`${styles.commandItem} ${index === activeIndex ? styles.commandItemActive : ''}`}
                    onMouseEnter={() => onSelectIndex(index)}
                    onClick={() => onExecuteCommand(command)}
                  >
                    <span className={styles.commandIcon}>
                      <Icon name={command.icon} size={14} />
                    </span>
                    <span className={styles.commandText}>
                      <strong>{command.label}</strong>
                      {command.description ? <small>{command.description}</small> : null}
                    </span>
                  </button>
                </li>
              ))}
              {filteredCommands.length === 0 ? (
                <li className={styles.emptyResults} role="status">
                  {t('noCommandsMatchQuery')}
                </li>
              ) : null}
            </ul>
          </motion.section>
        </motion.div>
      ) : null}
    </AnimatePresence>,
    document.body,
  );
}
