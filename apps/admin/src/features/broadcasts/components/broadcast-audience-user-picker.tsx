'use client';

import { useCallback, useEffect, useId, useMemo, useRef, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Field } from '@/components/ui';
import { fetchUsers } from '@/lib/api';
import { ADMIN_SEARCH_DEBOUNCE_MS } from '@/lib/utils/admin-ui-timing';
import { BROADCAST_RECIPIENT_CAP } from '../data/broadcast-audience-api';
import {
  formatBroadcastUserLabel,
  getBroadcastUserDisplayParts,
} from '../lib/format-user-display-label';
import type { BroadcastAudienceUser } from '../types';
import styles from './broadcast-audience-user-picker.module.css';

type BroadcastAudienceUserPickerProps = {
  selectedUsers: BroadcastAudienceUser[];
  onChange: (users: BroadcastAudienceUser[]) => void;
  disabled?: boolean;
};

type SearchUserRow = {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber: string;
};

export function BroadcastAudienceUserPicker({
  selectedUsers,
  onChange,
  disabled = false,
}: BroadcastAudienceUserPickerProps) {
  const t = useTranslations('broadcasts');
  const inputId = useId();
  const listId = useId();
  const rootRef = useRef<HTMLDivElement | null>(null);
  const optionRefs = useRef<Array<HTMLButtonElement | null>>([]);
  const [query, setQuery] = useState('');
  const [debouncedQuery, setDebouncedQuery] = useState('');
  const [open, setOpen] = useState(false);
  const [activeIndex, setActiveIndex] = useState(-1);
  const [results, setResults] = useState<SearchUserRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(false);

  const selectedIds = useMemo(() => new Set(selectedUsers.map((user) => user.id)), [selectedUsers]);
  const atCap = selectedUsers.length >= BROADCAST_RECIPIENT_CAP;

  useEffect(() => {
    const timer = window.setTimeout(() => setDebouncedQuery(query.trim()), ADMIN_SEARCH_DEBOUNCE_MS);
    return () => window.clearTimeout(timer);
  }, [query]);

  useEffect(() => {
    if (!open) return undefined;
    const onPointerDown = (event: MouseEvent) => {
      if (!rootRef.current?.contains(event.target as Node)) {
        setOpen(false);
        setActiveIndex(-1);
      }
    };
    document.addEventListener('pointerdown', onPointerDown);
    return () => document.removeEventListener('pointerdown', onPointerDown);
  }, [open]);

  useEffect(() => {
    if (!open) {
      optionRefs.current = [];
      return;
    }

    let cancelled = false;
    async function runSearch() {
      if (!debouncedQuery) {
        setResults([]);
        setActiveIndex(-1);
        setLoading(false);
        setError(false);
        return;
      }

      setLoading(true);
      setError(false);
      try {
        const response = await fetchUsers({
          search: debouncedQuery,
          status: 'ACTIVE',
          limit: 20,
          page: 1,
        });
        if (cancelled) return;
        const nextResults = response.data;
        const nextAvailable = nextResults.filter((user) => !selectedIds.has(user.id));
        setResults(nextResults);
        setActiveIndex(nextAvailable.length > 0 ? 0 : -1);
      } catch {
        if (!cancelled) {
          setResults([]);
          setActiveIndex(-1);
          setError(true);
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void runSearch();
    return () => {
      cancelled = true;
    };
  }, [debouncedQuery, open, selectedIds]);

  const availableResults = useMemo(
    () => results.filter((user) => !selectedIds.has(user.id)),
    [results, selectedIds],
  );

  useEffect(() => {
    if (!open) return;
    setActiveIndex(availableResults.length > 0 ? 0 : -1);
  }, [availableResults.length, debouncedQuery, open]);

  useEffect(() => {
    if (!open || activeIndex < 0) return;
    const node = optionRefs.current[activeIndex];
    if (!node?.isConnected) return;

    const frame = window.requestAnimationFrame(() => {
      if (!node.isConnected) return;
      node.scrollIntoView?.({ block: 'nearest' });
    });

    return () => window.cancelAnimationFrame(frame);
  }, [activeIndex, open]);

  const addUser = useCallback(
    (user: SearchUserRow) => {
      if (selectedIds.has(user.id) || atCap) return;
      onChange([
        ...selectedUsers,
        { id: user.id, label: formatBroadcastUserLabel(user) },
      ]);
      setQuery('');
      setDebouncedQuery('');
      setOpen(false);
      setActiveIndex(-1);
    },
    [atCap, onChange, selectedIds, selectedUsers],
  );

  const removeUser = useCallback(
    (userId: string) => {
      onChange(selectedUsers.filter((user) => user.id !== userId));
    },
    [onChange, selectedUsers],
  );

  const onKeyDown = (event: React.KeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'Escape') {
      event.preventDefault();
      setOpen(false);
      setActiveIndex(-1);
      return;
    }

    if (event.key === 'ArrowDown') {
      event.preventDefault();
      if (!open) {
        setOpen(true);
        return;
      }
      if (availableResults.length === 0) return;
      setActiveIndex((current) => Math.min(current + 1, availableResults.length - 1));
      return;
    }

    if (event.key === 'ArrowUp') {
      event.preventDefault();
      if (!open || availableResults.length === 0) return;
      setActiveIndex((current) => Math.max(current - 1, 0));
      return;
    }

    if (event.key === 'Home' && open && availableResults.length > 0) {
      event.preventDefault();
      setActiveIndex(0);
      return;
    }

    if (event.key === 'End' && open && availableResults.length > 0) {
      event.preventDefault();
      setActiveIndex(availableResults.length - 1);
      return;
    }

    if (event.key === 'Enter' && open && activeIndex >= 0) {
      event.preventDefault();
      const user = availableResults[activeIndex];
      if (user) addUser(user);
    }
  };

  const activeOptionId = activeIndex >= 0 ? `${listId}-option-${activeIndex}` : undefined;
  const showPanel = open && (loading || error || debouncedQuery.length > 0);
  const helperId = `${inputId}-help`;

  return (
    <div className={styles.root} ref={rootRef}>
      <Field
        label={t('form.searchUsers')}
        htmlFor={inputId}
        helperText={t('form.searchUsersHint')}
        className={styles.searchField}
      >
        <div className={styles.combobox}>
          <input
            id={inputId}
            className={styles.searchInput}
            type="search"
            role="combobox"
            aria-expanded={showPanel}
            aria-controls={showPanel ? listId : undefined}
            aria-activedescendant={showPanel ? activeOptionId : undefined}
            aria-autocomplete="list"
            aria-haspopup="listbox"
            aria-describedby={helperId}
            disabled={disabled || atCap}
            value={query}
            placeholder={t('form.searchUsersPlaceholder')}
            onChange={(event) => {
              setQuery(event.target.value);
              setOpen(true);
            }}
            onFocus={() => {
              if (query.trim()) setOpen(true);
            }}
            onKeyDown={onKeyDown}
          />
          {showPanel ? (
            <div id={listId} className={styles.options} role="listbox" aria-labelledby={inputId}>
              {loading ? (
                <div className={styles.statusMessage} role="presentation">
                  {t('form.searchingUsers')}
                </div>
              ) : error ? (
                <div className={styles.statusMessage} role="presentation">
                  {t('form.userSearchFailed')}
                </div>
              ) : availableResults.length === 0 ? (
                <div className={styles.emptyOption} role="presentation">
                  {t('form.noUsersFound')}
                </div>
              ) : (
                availableResults.map((user, index) => {
                const { primary, secondary } = getBroadcastUserDisplayParts(user);
                const isActive = index === activeIndex;
                return (
                  <button
                    key={user.id}
                    ref={(node) => {
                      optionRefs.current[index] = node;
                    }}
                    id={`${listId}-option-${index}`}
                    type="button"
                    role="option"
                    aria-selected={isActive}
                    className={isActive ? styles.optionActive : undefined}
                    disabled={atCap}
                    onMouseEnter={() => setActiveIndex(index)}
                    onClick={() => addUser(user)}
                  >
                    <span className={styles.optionContent}>
                      <span className={styles.optionPrimary}>{primary}</span>
                      {secondary ? (
                        <span className={styles.optionSecondary}>{secondary}</span>
                      ) : null}
                    </span>
                  </button>
                );
              })
            )}
          </div>
        ) : null}
        </div>
      </Field>

      <div className={styles.selectedSection}>
        <span className={styles.selectedLabel}>
          {t('form.selectedUsers', { count: selectedUsers.length })}
        </span>
        {selectedUsers.length > 0 ? (
          <div className={styles.chipRow}>
            {selectedUsers.map((user) => (
              <span key={user.id} className={styles.chip}>
                <span className={styles.chipLabel}>{user.label}</span>
                <button
                  type="button"
                  className={styles.chipRemove}
                  aria-label={t('form.removeUser', { name: user.label })}
                  disabled={disabled}
                  onClick={() => removeUser(user.id)}
                >
                  ×
                </button>
              </span>
            ))}
          </div>
        ) : (
          <p className={styles.emptySelected}>{t('form.noUsersSelected')}</p>
        )}
      </div>

      {atCap ? <p className={styles.warning}>{t('form.maxRecipientsReached')}</p> : null}
    </div>
  );
}
