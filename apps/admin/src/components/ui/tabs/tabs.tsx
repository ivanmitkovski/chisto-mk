'use client';

import { ReactNode, useMemo, useState } from 'react';
import styles from './tabs.module.css';

export type TabItem = {
  id: string;
  label: string;
  content: ReactNode;
};

type TabsProps = {
  items: TabItem[];
  defaultValue?: string;
  ariaLabel: string;
};

export function Tabs({ items, defaultValue, ariaLabel }: TabsProps) {
  const initial = defaultValue ?? items[0]?.id ?? '';
  const [activeId, setActiveId] = useState(initial);
  const active = useMemo(
    () => items.find((item) => item.id === activeId) ?? items[0],
    [activeId, items],
  );

  function focusTab(id: string) {
    setActiveId(id);
    document.getElementById(`${id}-tab`)?.focus();
  }

  function handleTabKeyDown(event: React.KeyboardEvent<HTMLDivElement>) {
    const currentIndex = items.findIndex((item) => item.id === activeId);
    if (currentIndex < 0) return;
    if (event.key === 'ArrowRight' || event.key === 'ArrowDown') {
      event.preventDefault();
      focusTab(items[(currentIndex + 1) % items.length]!.id);
    } else if (event.key === 'ArrowLeft' || event.key === 'ArrowUp') {
      event.preventDefault();
      focusTab(items[(currentIndex - 1 + items.length) % items.length]!.id);
    } else if (event.key === 'Home') {
      event.preventDefault();
      focusTab(items[0]!.id);
    } else if (event.key === 'End') {
      event.preventDefault();
      focusTab(items[items.length - 1]!.id);
    }
  }

  if (!active) return null;

  return (
    <div className={styles.root}>
      <div
        className={styles.list}
        role="tablist"
        aria-label={ariaLabel}
        onKeyDown={handleTabKeyDown}
      >
        {items.map((item) => {
          const selected = item.id === active.id;
          return (
            <button
              key={item.id}
              type="button"
              className={selected ? `${styles.tab} ${styles.tabActive}` : styles.tab}
              role="tab"
              id={`${item.id}-tab`}
              aria-selected={selected}
              aria-controls={`${item.id}-panel`}
              tabIndex={selected ? 0 : -1}
              onClick={() => setActiveId(item.id)}
            >
              {item.label}
            </button>
          );
        })}
      </div>
      <section
        className={styles.panel}
        role="tabpanel"
        id={`${active.id}-panel`}
        aria-labelledby={`${active.id}-tab`}
      >
        {active.content}
      </section>
    </div>
  );
}
