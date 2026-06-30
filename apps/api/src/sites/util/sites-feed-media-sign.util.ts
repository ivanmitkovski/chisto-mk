import { signPublicMediaUrlsDeduped } from '../../storage/util/batch-private-object-sign';

type RowWithMedia = {
  latestReportMediaUrls?: string[] | undefined;
  heroMediaUrls?: string[] | undefined;
};

export async function applyBatchSignedMediaToRows<T extends RowWithMedia>(
  rows: T[],
  signUrls: (unique: string[]) => Promise<string[]>,
): Promise<T[]> {
  const signedMediaByUrl = await signPublicMediaUrlsDeduped(
    rows.flatMap((row) => [...(row.heroMediaUrls ?? []), ...(row.latestReportMediaUrls ?? [])]),
    signUrls,
  );
  return rows.map((row) => {
    const signList = (urls: string[] | undefined) => {
      if (!urls?.length) return urls;
      return urls.map((url) => signedMediaByUrl.get(url.trim()) ?? url);
    };
    if (!row.latestReportMediaUrls?.length && !row.heroMediaUrls?.length) {
      return row;
    }
    return {
      ...row,
      latestReportMediaUrls: signList(row.latestReportMediaUrls),
      heroMediaUrls: signList(row.heroMediaUrls),
    };
  });
}
