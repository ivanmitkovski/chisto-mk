/**
 * Deduplicates object keys and signs each once (parallel). Use on hot paths
 * that would otherwise call the signer once per row.
 */
export async function signPrivateObjectKeysDeduped(
  keys: Iterable<string | null | undefined>,
  signOne: (objectKey: string) => Promise<string | null>,
): Promise<Map<string, string | null>> {
  const unique = [
    ...new Set(
      [...keys].filter((k): k is string => typeof k === 'string' && k.trim().length > 0),
    ),
  ];
  const urlByKey = new Map<string, string | null>();
  await Promise.all(
    unique.map(async (key) => {
      urlByKey.set(key, await signOne(key));
    }),
  );
  return urlByKey;
}

/**
 * Dedupes canonical media URL strings, signs each distinct value once via `signUrls`,
 * then maps originals → signed (same contract as {@link signPrivateObjectKeysDeduped}).
 */
export async function signPublicMediaUrlsDeduped(
  urls: Iterable<string>,
  signUrlsBatch: (uniqueUrls: string[]) => Promise<string[]>,
): Promise<Map<string, string>> {
  const unique = [...new Set([...urls].map((u) => u.trim()).filter((u) => u.length > 0))];
  if (unique.length === 0) {
    return new Map();
  }
  const signed = await signUrlsBatch(unique);
  const out = new Map<string, string>();
  for (let i = 0; i < unique.length; i++) {
    out.set(unique[i], signed[i] ?? unique[i]);
  }
  return out;
}
