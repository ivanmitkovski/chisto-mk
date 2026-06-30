import { describe, expect, it } from 'vitest';
import { adminNavigation } from './navigation';

describe('adminNavigation', () => {
  it('assigns a unique icon to every sidebar item', () => {
    const icons = adminNavigation.map((item) => item.icon);
    expect(new Set(icons).size).toBe(icons.length);
  });
});
