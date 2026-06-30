import { describe, expect, it } from 'vitest';
import {
  CORE_MESSAGE_NAMESPACES,
  DASHBOARD_SCOPED_NAMESPACES,
  getNamespacesForPathname,
  loadMessages,
} from './load-messages';
import { getStaticNewsMessages } from './static-news-messages';
import { messagesSatisfyPathname, mergeRouteMessages } from './route-messages-client';

describe('loadMessages', () => {
  it('loads remove block dialog keys for en news', async () => {
    const messages = await loadMessages('en', ['news']);
    const confirm = (messages.news as { confirm: Record<string, string> }).confirm;
    expect(confirm.removeBlockUndoHint).toBeTruthy();
    expect(confirm.removeBlockPosition).toBeTruthy();
  });
});

describe('getStaticNewsMessages', () => {
  it('includes remove block dialog keys', () => {
    expect(getStaticNewsMessages('en').confirm.removeBlockUndoHint).toBeTruthy();
  });
});

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

  it('prefers later namespaces when merging (fresh over stale prefetch)', () => {
    const stale = {
      news: {
        confirm: {
          removeBlockTitle: 'Old title',
          removeBlockBody: 'The {type} block will be removed.',
        },
      },
    };
    const fresh = {
      news: {
        confirm: {
          removeBlockTitle: 'New title',
          removeBlockBody: 'This section will be removed from your current draft.',
          removeBlockCancel: 'Keep section',
        },
      },
    };

    expect(mergeRouteMessages(stale, fresh).news).toEqual(fresh.news);
  });

  it('deep-merges nested keys inside a namespace', () => {
    const base = {
      news: {
        confirm: {
          removeBlockTitle: 'Old title',
          removeBlockBody: 'The {type} block will be removed.',
        },
        form: {
          removeBlock: 'Remove',
        },
      },
    };
    const override = {
      news: {
        confirm: {
          removeBlockBody: 'This section will be removed from your current draft.',
          removeBlockCancel: 'Keep section',
        },
      },
    };

    expect(mergeRouteMessages(base, override)).toEqual({
      news: {
        confirm: {
          removeBlockTitle: 'Old title',
          removeBlockBody: 'This section will be removed from your current draft.',
          removeBlockCancel: 'Keep section',
        },
        form: {
          removeBlock: 'Remove',
        },
      },
    });
  });
});
