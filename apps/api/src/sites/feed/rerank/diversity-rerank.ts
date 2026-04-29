import { Injectable } from '@nestjs/common';
import { FeedCandidate } from '../feed-v2.types';

@Injectable()
export class DiversityRerank {
  apply(rows: FeedCandidate[]): FeedCandidate[] {
    if (rows.length < 4) return rows;
    const out: FeedCandidate[] = [];
    const pending = [...rows];
    while (pending.length > 0) {
      if (out.length < 2) {
        out.push(pending.shift() as FeedCandidate);
        continue;
      }
      const prev = out[out.length - 1];
      const idx = pending.findIndex(
        (row) =>
          row.latestReportCategory !== prev.latestReportCategory &&
          row.latestReportReporterId !== prev.latestReportReporterId,
      );
      if (idx >= 0 && idx <= 3) {
        out.push(...pending.splice(idx, 1));
      } else {
        out.push(pending.shift() as FeedCandidate);
      }
    }
    return out;
  }
}
