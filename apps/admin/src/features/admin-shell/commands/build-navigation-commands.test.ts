import { describe, expect, it } from 'vitest';
import { adminNavigation } from '../config/navigation';
import { NAV_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { buildNavigationCommands, getNavigationCommandIds } from './build-navigation-commands';

describe('buildNavigationCommands', () => {
  it('covers every adminNavigation item', () => {
    const commands = buildNavigationCommands();
    expect(commands).toHaveLength(adminNavigation.length);
    expect(getNavigationCommandIds()).toEqual(adminNavigation.map((item) => `go-${item.key}`));
  });

  it('maps hrefs and permissions from nav config', () => {
    const commands = buildNavigationCommands();
    for (const item of adminNavigation) {
      const command = commands.find((entry) => entry.id === `go-${item.key}`);
      expect(command, `missing command for ${item.key}`).toBeDefined();
      expect(command?.href).toBe(item.href);
      expect(command?.permission).toBe(NAV_PERMISSIONS[item.key]);
      expect(command?.action).toEqual({ type: 'navigate', href: item.href });
    }
  });

  it('includes active-users and resolutions', () => {
    const ids = getNavigationCommandIds();
    expect(ids).toContain('go-active-users');
    expect(ids).toContain('go-resolutions');
  });
});
