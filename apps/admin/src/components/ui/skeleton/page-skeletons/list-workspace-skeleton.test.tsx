import { describe, expect, it } from 'vitest';
import { render } from '@testing-library/react';
import styles from '../skeleton.module.css';
import { ListWorkspaceSkeleton } from './list-workspace-skeleton';

describe('ListWorkspaceSkeleton', () => {
  it('is exported as a render function', () => {
    expect(typeof ListWorkspaceSkeleton).toBe('function');
    expect(ListWorkspaceSkeleton.name).toBe('ListWorkspaceSkeleton');
  });

  it('stacks sections with pageStack and wraps toolbar and table in workspaceTableCard', () => {
    const { container } = render(<ListWorkspaceSkeleton statCount={3} tableCols={8} />);

    const pageStack = container.querySelector(`.${styles.pageStack}`);
    expect(pageStack).toBeTruthy();

    const tableCard = container.querySelector(`.${styles.workspaceTableCard}`);
    expect(tableCard).toBeTruthy();
    expect(tableCard?.querySelector('table')).toBeTruthy();
    expect(tableCard?.querySelector(`.${styles.toolbarSkeleton}`)).toBeTruthy();
    expect(tableCard?.querySelector(`.${styles.workspaceTableCardInner}`)).toBeTruthy();
  });

  it('keeps the table inside workspaceTableCard when toolbar is hidden', () => {
    const { container } = render(
      <ListWorkspaceSkeleton showToolbar={false} showStats={false} tableCols={4} />,
    );

    const tableCard = container.querySelector(`.${styles.workspaceTableCard}`);
    expect(tableCard?.querySelector('table')).toBeTruthy();
    expect(tableCard?.querySelector(`.${styles.toolbarSkeleton}`)).toBeNull();
  });
});
