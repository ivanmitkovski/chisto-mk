import { PrismaClient } from '../src/generated/prisma';

const prisma = new PrismaClient();

async function main() {
  let cursor: string | undefined;
  const batch = 300;
  let processed = 0;

  while (true) {
    const rows = await prisma.site.findMany({
      where: cursor ? { id: { gt: cursor } } : undefined,
      orderBy: { id: 'asc' },
      take: batch,
      include: {
        reports: {
          orderBy: { createdAt: 'desc' },
          take: 1,
          select: {
            title: true,
            description: true,
            category: true,
            reportNumber: true,
            createdAt: true,
            mediaUrls: true,
          },
        },
        _count: { select: { reports: true } },
      },
    });

    if (rows.length === 0) break;

    for (const site of rows) {
      const latest = site.reports[0];
      const isHot =
        site.status !== 'CLEANED' ||
        site.updatedAt.getTime() > Date.now() - 90 * 24 * 60 * 60 * 1000;

      await prisma.$executeRaw`
        INSERT INTO "MapSiteProjection" (
          "siteId","latitude","longitude","status","address","description","thumbnailUrl",
          "pollutionCategory","latestReportTitle","latestReportDescription","latestReportNumber",
          "reportCount","upvotesCount","commentsCount","savesCount","sharesCount",
          "latestReportAt","siteCreatedAt","siteUpdatedAt","projectedAt","isHot"
        ) VALUES (
          ${site.id},${site.latitude},${site.longitude},${site.status}::"SiteStatus",${site.address},${site.description},${latest?.mediaUrls?.[0] ?? null},
          ${latest?.category ?? null},${latest?.title ?? null},${latest?.description ?? null},${latest?.reportNumber ?? null},
          ${site._count.reports},${site.upvotesCount},${site.commentsCount},${site.savesCount},${site.sharesCount},
          ${latest?.createdAt ?? null},${site.createdAt},${site.updatedAt},NOW(),${isHot}
        )
        ON CONFLICT ("siteId") DO UPDATE
        SET
          "latitude" = EXCLUDED."latitude",
          "longitude" = EXCLUDED."longitude",
          "status" = EXCLUDED."status",
          "address" = EXCLUDED."address",
          "description" = EXCLUDED."description",
          "thumbnailUrl" = EXCLUDED."thumbnailUrl",
          "pollutionCategory" = EXCLUDED."pollutionCategory",
          "latestReportTitle" = EXCLUDED."latestReportTitle",
          "latestReportDescription" = EXCLUDED."latestReportDescription",
          "latestReportNumber" = EXCLUDED."latestReportNumber",
          "reportCount" = EXCLUDED."reportCount",
          "upvotesCount" = EXCLUDED."upvotesCount",
          "commentsCount" = EXCLUDED."commentsCount",
          "savesCount" = EXCLUDED."savesCount",
          "sharesCount" = EXCLUDED."sharesCount",
          "latestReportAt" = EXCLUDED."latestReportAt",
          "siteCreatedAt" = EXCLUDED."siteCreatedAt",
          "siteUpdatedAt" = EXCLUDED."siteUpdatedAt",
          "projectedAt" = NOW(),
          "isHot" = EXCLUDED."isHot";
      `;
      processed += 1;
    }

    cursor = rows[rows.length - 1].id;
    console.log(`processed ${processed}`);
  }

  console.log(`done, processed ${processed} sites`);

  console.log('backfilling geo column on MapSiteProjection...');
  const projGeoCount = await prisma.$executeRaw`
    UPDATE "MapSiteProjection"
    SET "geo" = ST_SetSRID(ST_MakePoint("longitude", "latitude"), 4326)::geography
    WHERE "geo" IS NULL
  `;
  console.log(`MapSiteProjection geo backfill: ${projGeoCount} rows`);

  console.log('backfilling geo column on Site...');
  const siteGeoCount = await prisma.$executeRaw`
    UPDATE "Site"
    SET "geo" = ST_SetSRID(ST_MakePoint("longitude", "latitude"), 4326)::geography
    WHERE "geo" IS NULL
  `;
  console.log(`Site geo backfill: ${siteGeoCount} rows`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
