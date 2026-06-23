'use client';

import { ChangeEvent, useEffect, useMemo, useState } from 'react';
import { useCommandRegistry } from '../commands/use-command-registry';

type UseCommandPaletteOptions = {
  isOpen: boolean;
};

export function useCommandPalette({ isOpen }: UseCommandPaletteOptions) {
  const [query, setQuery] = useState('');
  const [activeIndex, setActiveIndex] = useState(0);

  const registry = useCommandRegistry({ query, isOpen });
  const { flatResults } = registry;

  useEffect(() => {
    if (!isOpen) return;
    setQuery('');
    setActiveIndex(0);
  }, [isOpen]);

  useEffect(() => {
    if (flatResults.length === 0) {
      setActiveIndex(0);
      return;
    }
    setActiveIndex((prev) => Math.min(prev, flatResults.length - 1));
  }, [flatResults]);

  function onQueryChange(event: ChangeEvent<HTMLInputElement>) {
    setQuery(event.target.value);
    setActiveIndex(0);
  }

  function moveSelection(step: 1 | -1) {
    if (flatResults.length === 0) return;
    setActiveIndex((prev) => {
      const nextIndex = prev + step;
      if (nextIndex < 0) return flatResults.length - 1;
      if (nextIndex >= flatResults.length) return 0;
      return nextIndex;
    });
  }

  function moveToBoundary(target: 'start' | 'end') {
    if (flatResults.length === 0) return;
    setActiveIndex(target === 'start' ? 0 : flatResults.length - 1);
  }

  const activeItem = useMemo(() => flatResults[activeIndex] ?? null, [flatResults, activeIndex]);

  return {
    query,
    activeIndex,
    activeItem,
    onQueryChange,
    moveSelection,
    moveToBoundary,
    selectIndex: setActiveIndex,
    ...registry,
  };
}
