import { signPublicMediaUrlsDeduped } from '../storage/batch-private-object-sign';

type RowWithMedia = { latestReportMediaUrls?: string[] };

export async function applyBatchSignedMediaToRows<T extends RowWithMedia>(
  rows: T[],
  signUrls: (unique: string[]) => Promise<string[]>,
): Promise<T[]> {
  const signedMediaByUrl = await signPublicMediaUrlsDeduped(
    rows.flatMap((row) => row.latestReportMediaUrls ?? []),
    signUrls,
  );
  return rows.map((row) => {
    if (!row.latestReportMediaUrls?.length) {
      return row;
    }
    return {
      ...row,
      latestReportMediaUrls: row.latestReportMediaUrls.map(
        (url) => signedMediaByUrl.get(url.trim()) ?? url,
      ),
    };
  });
}
