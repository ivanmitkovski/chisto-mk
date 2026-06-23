import { describe, expect, it } from 'vitest';
import {
  CORE_MESSAGE_NAMESPACES,
  DASHBOARD_SCOPED_NAMESPACES,
  getNamespacesForPathname,
} from './load-messages';
import { messagesSatisfyPathname } from './route-messages-client';

describe('getNamespacesForPathname', () => {
  it('loads the full dashboard bundle for dashboard routes', () => {
    const namespaces = getNamespacesForPathname('/dashboard/map');
    expect(namespaces).toContain('map');
    expect(namespaces).toContain('users');
    expect(namespaces).toContain('settings');
    for (const namespace of DASHBOARD_SCOPED_NAMESPACES) {
      expect(namespaces).toContain(namespace);
    }
    for (const namespace of CORE_MESSAGE_NAMESPACES) {
      expect(namespaces).toContain(namespace);
    }
  });

  it('loads auth for login', () => {
    const namespaces = getNamespacesForPathname('/login');
    expect(namespaces).toContain('auth');
    expect(namespaces).not.toContain('map');
  });
});

describe('messagesSatisfyPathname', () => {
  it('detects missing namespaces for a route', () => {
    expect(messagesSatisfyPathname('/dashboard/map', { common: {}, nav: {} })).toBe(false);
    expect(
      messagesSatisfyPathname('/dashboard/map', {
        common: {},
        nav: {},
        ui: {},
        auth: {},
        errors: {},
        commandPalette: {},
        map: {},
        ...Object.fromEntries(DASHBOARD_SCOPED_NAMESPACES.map((namespace) => [namespace, {}])),
      }),
    ).toBe(true);
  });
});
