import { ChangeEvent, useEffect, useMemo, useState } from 'react';
import { TopBarCommand } from '../types/top-bar';

type UseCommandPaletteOptions = {
  isOpen: boolean;
  commands: ReadonlyArray<TopBarCommand>;
};

function normalize(value: string) {
  return value.trim().toLowerCase();
}

export function useCommandPalette({ isOpen, commands }: UseCommandPaletteOptions) {
  const [query, setQuery] = useState('');
  const [activeIndex, setActiveIndex] = useState(0);

  const filteredCommands = useMemo(() => {
    const normalizedQuery = normalize(query);

    if (!normalizedQuery) {
      return commands;
    }

    return commands.filter((command) => {
      const fullText = [command.label, command.description ?? '', ...command.keywords].join(' ');
      return normalize(fullText).includes(normalizedQuery);
    });
  }, [commands, query]);

  useEffect(() => {
    if (!isOpen) {
      return;
    }

    setQuery('');
    setActiveIndex(0);
  }, [isOpen]);

  useEffect(() => {
    if (filteredCommands.length === 0) {
      setActiveIndex(0);
      return;
    }

    setActiveIndex((prev) => Math.min(prev, filteredCommands.length - 1));
  }, [filteredCommands]);

  function onQueryChange(event: ChangeEvent<HTMLInputElement>) {
    setQuery(event.target.value);
    setActiveIndex(0);
  }

  function moveSelection(step: 1 | -1) {
    if (filteredCommands.length === 0) {
      return;
    }

    setActiveIndex((prev) => {
      const nextIndex = prev + step;

      if (nextIndex < 0) {
        return filteredCommands.length - 1;
      }

      if (nextIndex >= filteredCommands.length) {
        return 0;
      }

      return nextIndex;
    });
  }

  function moveToBoundary(target: 'start' | 'end') {
    if (filteredCommands.length === 0) {
      return;
    }

    setActiveIndex(target === 'start' ? 0 : filteredCommands.length - 1);
  }

  return {
    query,
    activeIndex,
    filteredCommands,
    onQueryChange,
    moveSelection,
    moveToBoundary,
    selectIndex: setActiveIndex,
    activeCommand: filteredCommands[activeIndex] ?? null,
  };
}
