/**
 * Backfill Typesense `map_sites` collection from Postgres.
 *
 * Requires MAP_SEARCH_TYPESENSE=true, TYPESENSE_HOST, TYPESENSE_API_KEY.
 * Usage: pnpm --filter @chisto/api exec tsx scripts/typesense-backfill-sites.ts
 */
import 'dotenv/config';
import { PrismaClient } from '../src/generated/prisma';
import { TypesenseClientService } from '../src/sites/search/typesense/typesense-client.service';
import { TypesenseSitesIndexService } from '../src/sites/search/typesense/typesense-sites-index.service';

const prisma = new PrismaClient();

async function main() {
  const typesenseClient = new TypesenseClientService();
  typesenseClient.onModuleInit();

  if (!typesenseClient.isEnabled()) {
    console.error(
      'Typesense is not enabled. Set MAP_SEARCH_TYPESENSE=true plus TYPESENSE_HOST and TYPESENSE_API_KEY.',
    );
    process.exit(1);
  }

  const index = new TypesenseSitesIndexService(typesenseClient, prisma as never);
  await index.ensureCollection();

  let cursor: string | undefined;
  const batch = 200;
  let processed = 0;

  while (true) {
    const sites = await prisma.site.findMany({
      where: cursor ? { id: { gt: cursor } } : undefined,
      orderBy: { id: 'asc' },
      take: batch,
      select: { id: true },
    });
    if (sites.length === 0) break;

    for (const site of sites) {
      await index.upsertSite(site.id);
      processed += 1;
    }

    cursor = sites[sites.length - 1].id;
    console.log(`indexed ${processed} sites`);
  }

  console.log(`Typesense backfill complete (${processed} sites).`);
}

main()
  .catch((err) => {
    console.error(err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
