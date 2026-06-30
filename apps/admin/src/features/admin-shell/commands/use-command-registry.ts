'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { usePathname } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { ADMIN_SEARCH_DEBOUNCE_MS } from '@/lib/utils/admin-ui-timing';
import { usePermissions } from '@/lib/auth/rbac/use-permissions';
import { buildNavigationCommands } from './build-navigation-commands';
import { getContextualCommands } from './contextual-commands';
import { globalCommands } from './global-commands';
import { fetchEntityCommands } from './entity-search-providers';
import { searchCommands } from './command-search';
import { resolveCommands } from './resolve-command';
import {
  clearRecentCommands,
  filterRecentIds,
  loadRecentCommandIds,
  recordRecentCommand,
} from './recents';
import {
  COMMAND_GROUP_ORDER,
  type CommandDefinition,
  type CommandGroup,
  type ResolvedCommand,
  type ScoredCommand,
} from './types';

const navigationCommands = buildNavigationCommands();

export type GroupedCommands = {
  group: CommandGroup;
  items: ScoredCommand[];
};

type UseCommandRegistryOptions = {
  query: string;
  isOpen: boolean;
};

export function useCommandRegistry({ query, isOpen }: UseCommandRegistryOptions) {
  const pathname = usePathname();
  const { can } = usePermissions();
  const tNav = useTranslations('nav');
  const tCommon = useTranslations('common');
  const tPalette = useTranslations('commandPalette');

  const [recentIds, setRecentIds] = useState<string[]>([]);
  const [entityCommands, setEntityCommands] = useState<CommandDefinition[]>([]);
  const [entityLoading, setEntityLoading] = useState(false);
  const [entityErrors, setEntityErrors] = useState<Partial<Record<'users' | 'reports' | 'sites', string>>>({});

  useEffect(() => {
    if (!isOpen) return;
    setRecentIds(loadRecentCommandIds());
  }, [isOpen]);

  const staticDefinitions = useMemo(() => {
    const contextual = getContextualCommands(pathname);
    const globals = globalCommands.filter(
      (command) => command.id !== 'clear-recents' || recentIds.length > 0,
    );
    return [...navigationCommands, ...contextual, ...globals];
  }, [pathname, recentIds.length]);

  const permittedDefinitions = useMemo(
    () => staticDefinitions.filter((command) => !command.permission || can(command.permission)),
    [can, staticDefinitions],
  );

  const permittedEntityDefinitions = useMemo(
    () => entityCommands.filter((command) => !command.permission || can(command.permission)),
    [can, entityCommands],
  );

  const allDefinitions = useMemo(
    () => [...permittedDefinitions, ...permittedEntityDefinitions],
    [permittedDefinitions, permittedEntityDefinitions],
  );

  const resolvedStatic = useMemo(
    () => resolveCommands(permittedDefinitions, tNav, tCommon, tPalette),
    [permittedDefinitions, tNav, tCommon, tPalette],
  );

  const resolvedEntity = useMemo(
    () => resolveCommands(permittedEntityDefinitions, tNav, tCommon, tPalette),
    [permittedEntityDefinitions, tNav, tCommon, tPalette],
  );

  const resolvedAll = useMemo(
    () => [...resolvedStatic, ...resolvedEntity],
    [resolvedStatic, resolvedEntity],
  );

  const allowedIds = useMemo(() => new Set(allDefinitions.map((c) => c.id)), [allDefinitions]);

  const safeRecentIds = useMemo(
    () => filterRecentIds(recentIds, allowedIds),
    [recentIds, allowedIds],
  );

  const recentResolved = useMemo(() => {
    const byId = new Map(resolvedAll.map((command) => [command.id, command]));
    return safeRecentIds
      .map((id) => byId.get(id))
      .filter((command): command is ResolvedCommand => Boolean(command))
      .map((command) => ({
        command: { ...command, group: 'recent' as const },
        score: 100,
      }));
  }, [resolvedAll, safeRecentIds]);

  const scoredStatic = useMemo(() => {
    const normalized = query.trim();
    if (!normalized) return [];
    return searchCommands(resolvedStatic, query, safeRecentIds);
  }, [query, resolvedStatic, safeRecentIds]);

  const scoredEntity = useMemo(() => {
    const normalized = query.trim();
    if (!normalized) return [];
    return searchCommands(resolvedEntity, query, safeRecentIds);
  }, [query, resolvedEntity, safeRecentIds]);

  const flatResults = useMemo((): ScoredCommand[] => {
    const normalized = query.trim();
    if (!normalized) {
      const recentIdsInResults = new Set(recentResolved.map((item) => item.command.id));
      const navigation = resolvedStatic
        .filter((command) => command.group === 'navigation' && !recentIdsInResults.has(command.id))
        .map((command) => ({ command, score: 0 }));
      const actions = resolvedStatic
        .filter((command) => command.group !== 'navigation' && !recentIdsInResults.has(command.id))
        .map((command) => ({ command, score: 0 }));
      return [...recentResolved, ...navigation, ...actions];
    }
    return [...scoredStatic, ...scoredEntity].sort((a, b) => b.score - a.score);
  }, [query, recentResolved, resolvedStatic, scoredStatic, scoredEntity]);

  const groupedResults = useMemo((): GroupedCommands[] => {
    const normalized = query.trim();
    const buckets = new Map<CommandGroup, ScoredCommand[]>();

    for (const item of flatResults) {
      const group = normalized ? item.command.group : item.command.group;
      const existing = buckets.get(group) ?? [];
      existing.push(item);
      buckets.set(group, existing);
    }

    return COMMAND_GROUP_ORDER.filter((group) => buckets.has(group)).map((group) => ({
      group,
      items: buckets.get(group) ?? [],
    }));
  }, [flatResults, query]);

  useEffect(() => {
    if (!isOpen) {
      setEntityCommands([]);
      setEntityLoading(false);
      setEntityErrors({});
      return;
    }

    const trimmed = query.trim();
    if (trimmed.length < 2 || trimmed.startsWith('/') || trimmed.includes('/dashboard')) {
      setEntityCommands([]);
      setEntityLoading(false);
      setEntityErrors({});
      return;
    }

    const controller = new AbortController();
    const timer = window.setTimeout(() => {
      setEntityLoading(true);
      void fetchEntityCommands(trimmed, can, controller.signal)
        .then((commands) => {
          if (controller.signal.aborted) return;
          setEntityCommands(commands);
          setEntityErrors({});
        })
        .catch(() => {
          if (controller.signal.aborted) return;
          setEntityErrors({ users: 'failed', reports: 'failed', sites: 'failed' });
        })
        .finally(() => {
          if (!controller.signal.aborted) setEntityLoading(false);
        });
    }, ADMIN_SEARCH_DEBOUNCE_MS);

    return () => {
      controller.abort();
      window.clearTimeout(timer);
    };
  }, [can, isOpen, query]);

  const recordRecent = useCallback((commandId: string) => {
    if (commandId.startsWith('clear-')) return;
    recordRecentCommand(commandId);
    setRecentIds(loadRecentCommandIds());
  }, []);

  const clearRecents = useCallback(() => {
    clearRecentCommands();
    setRecentIds([]);
  }, []);

  return {
    flatResults,
    groupedResults,
    entityLoading,
    entityErrors,
    recordRecent,
    clearRecents,
    resultCount: flatResults.length,
  };
}
