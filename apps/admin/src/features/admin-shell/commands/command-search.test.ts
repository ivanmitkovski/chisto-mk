import { describe, expect, it } from 'vitest';
import { searchCommands } from './command-search';
import type { ResolvedCommand } from './types';

function makeCommand(overrides: Partial<ResolvedCommand> & Pick<ResolvedCommand, 'id' | 'label'>): ResolvedCommand {
  return {
    group: 'navigation',
    labelKey: 'x',
    icon: 'home',
    action: { type: 'navigate', href: '/dashboard/users' },
    searchKeywords: [],
    ...overrides,
  };
}

describe('searchCommands', () => {
  const commands: ResolvedCommand[] = [
    makeCommand({
      id: 'go-users',
      label: 'Go to Users',
      description: 'Browse users',
      href: '/dashboard/users',
      searchKeywords: ['users', 'accounts'],
    }),
    makeCommand({
      id: 'go-reports',
      label: 'Go to Reports',
      href: '/dashboard/reports',
      searchKeywords: ['reports'],
    }),
  ];

  it('returns all commands for empty query', () => {
    const results = searchCommands(commands, '');
    expect(results).toHaveLength(2);
  });

  it('matches label tokens with AND semantics', () => {
    const results = searchCommands(commands, 'go users');
    expect(results[0]?.command.id).toBe('go-users');
  });

  it('matches href path queries', () => {
    const results = searchCommands(commands, '/dashboard/reports');
    expect(results.some((item) => item.command.id === 'go-reports')).toBe(true);
  });

  it('boosts recent command ids on empty query', () => {
    const without = searchCommands(commands, '', []);
    const withRecent = searchCommands(commands, '', ['go-reports']);
    const recentScore = withRecent.find((item) => item.command.id === 'go-reports')?.score ?? 0;
    const baseScore = without.find((item) => item.command.id === 'go-reports')?.score ?? 0;
    expect(recentScore).toBeGreaterThan(baseScore);
  });
});
