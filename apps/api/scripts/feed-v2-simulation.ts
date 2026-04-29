/// <reference types="node" />
/* eslint-disable no-console */
type FeedSite = {
  id: string;
  latestReportCategory?: string | null;
};

type FeedResponse = {
  data: FeedSite[];
};

type RunSummary = {
  totalRequests: number;
  p95Ms: number;
  avgMs: number;
  categoryCoverage: Record<string, number>;
};

async function main(): Promise<void> {
  const baseUrl = process.env.FEED_SIM_BASE_URL?.trim();
  if (!baseUrl) {
    throw new Error('FEED_SIM_BASE_URL is required, e.g. http://localhost:3000');
  }
  const token = process.env.FEED_SIM_TOKEN?.trim();
  const requests = Number(process.env.FEED_SIM_REQUESTS ?? '200');
  const concurrency = Number(process.env.FEED_SIM_CONCURRENCY ?? '20');
  const durations: number[] = [];
  const categorySeen = new Map<string, number>();

  let cursor = 0;
  const workers = Array.from({ length: Math.max(1, concurrency) }, async () => {
    while (true) {
      const i = cursor++;
      if (i >= requests) break;
      const startedAt = Date.now();
      const response = await fetch(
        `${baseUrl}/sites?page=1&limit=24&sort=hybrid&mode=for_you&status=VERIFIED&explain=true`,
        {
          headers: {
            ...(token ? { Authorization: `Bearer ${token}` } : {}),
          },
        },
      );
      const ms = Date.now() - startedAt;
      durations.push(ms);
      if (!response.ok) {
        continue;
      }
      const body = (await response.json()) as FeedResponse;
      for (const row of body.data ?? []) {
        const category = row.latestReportCategory?.toUpperCase() ?? 'UNKNOWN';
        categorySeen.set(category, (categorySeen.get(category) ?? 0) + 1);
      }
    }
  });
  await Promise.all(workers);
  durations.sort((a, b) => a - b);
  const p95Idx = Math.min(durations.length - 1, Math.floor(0.95 * durations.length));
  const summary: RunSummary = {
    totalRequests: durations.length,
    p95Ms: durations[p95Idx] ?? 0,
    avgMs:
      durations.length > 0 ? Number((durations.reduce((acc, v) => acc + v, 0) / durations.length).toFixed(2)) : 0,
    categoryCoverage: Object.fromEntries([...categorySeen.entries()].sort((a, b) => b[1] - a[1])),
  };
  console.log(JSON.stringify(summary, null, 2));
}

void main().catch((error: unknown) => {
  console.error(error);
  process.exit(1);
});
