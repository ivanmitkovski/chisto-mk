import { ListSitesQueryDto, SiteFeedMode, SiteFeedSort } from './dto/list-sites-query.dto';

export function applyDiversityRerank<
  T extends {
    id: string;
    latestReportCategory: string | null;
    latestReportReporterId?: string | null;
    rankingScore: number;
  },
>(rows: T[], query: ListSitesQueryDto): T[] {
  if (query.sort !== SiteFeedSort.HYBRID || query.mode === SiteFeedMode.LATEST || rows.length < 4) {
    return rows;
  }
  const output: T[] = [];
  const remaining = [...rows];
  while (remaining.length > 0) {
    if (output.length < 2) {
      output.push(remaining.shift() as T);
      continue;
    }
    const prevCategory = output[output.length - 1].latestReportCategory;
    const prevAuthor = output[output.length - 1].latestReportReporterId ?? null;
    const candidateIndex = remaining.findIndex(
      (item) =>
        item.latestReportCategory !== prevCategory &&
        (item.latestReportReporterId ?? null) !== prevAuthor,
    );
    if (candidateIndex >= 0 && candidateIndex <= 3) {
      output.push(...remaining.splice(candidateIndex, 1));
    } else {
      output.push(remaining.shift() as T);
    }
  }
  return output;
}
