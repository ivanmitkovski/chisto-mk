import { SkeletonPageHeader } from '../skeleton-page-header';
import { SkeletonStatStrip } from '../skeleton-stat-strip';
import { SkeletonTable } from '../skeleton-table';
import { SkeletonToolbar } from '../skeleton-toolbar';

type ListWorkspaceSkeletonProps = {
  tableRows?: number;
  tableCols?: number;
  statCount?: number;
  showStats?: boolean;
  showToolbar?: boolean;
  showPageHeader?: boolean;
};

export function ListWorkspaceSkeleton({
  tableRows = 8,
  tableCols = 5,
  statCount = 4,
  showStats = true,
  showToolbar = true,
  showPageHeader = false,
}: ListWorkspaceSkeletonProps) {
  return (
    <>
      {showPageHeader ? <SkeletonPageHeader /> : null}
      {showStats ? <SkeletonStatStrip count={statCount} /> : null}
      {showToolbar ? <SkeletonToolbar /> : null}
      <SkeletonTable rows={tableRows} cols={tableCols} />
    </>
  );
}
