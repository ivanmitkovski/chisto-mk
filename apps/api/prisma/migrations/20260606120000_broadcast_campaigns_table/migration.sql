-- CreateEnum
CREATE TYPE "BroadcastCampaignStatus" AS ENUM ('DRAFT', 'SCHEDULED', 'SENT', 'CANCELLED');

-- CreateEnum
CREATE TYPE "BroadcastAudience" AS ENUM ('ALL', 'ACTIVE', 'AREA', 'USERS');

-- CreateTable
CREATE TABLE "BroadcastCampaign" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "type" TEXT NOT NULL DEFAULT 'SYSTEM',
    "deeplink" TEXT,
    "audience" "BroadcastAudience" NOT NULL,
    "audienceUserIds" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "status" "BroadcastCampaignStatus" NOT NULL DEFAULT 'DRAFT',
    "scheduledAt" TIMESTAMP(3),
    "sentAt" TIMESTAMP(3),
    "sentCount" INTEGER,
    "createdById" TEXT,

    CONSTRAINT "BroadcastCampaign_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "BroadcastCampaign_status_scheduledAt_idx" ON "BroadcastCampaign"("status", "scheduledAt");

-- CreateIndex
CREATE INDEX "BroadcastCampaign_createdAt_idx" ON "BroadcastCampaign"("createdAt" DESC);

-- AddForeignKey
ALTER TABLE "BroadcastCampaign" ADD CONSTRAINT "BroadcastCampaign_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Backfill from legacy SystemConfig JSON blob (admin_broadcast_campaigns)
INSERT INTO "BroadcastCampaign" (
    "id",
    "createdAt",
    "updatedAt",
    "title",
    "body",
    "type",
    "deeplink",
    "audience",
    "audienceUserIds",
    "status",
    "scheduledAt",
    "sentAt",
    "sentCount",
    "createdById"
)
SELECT
    elem->>'id',
    COALESCE(NULLIF(elem->>'createdAt', '')::timestamptz, NOW()),
    COALESCE(NULLIF(elem->>'updatedAt', '')::timestamptz, NOW()),
    elem->>'title',
    elem->>'body',
    COALESCE(NULLIF(elem->>'type', ''), 'SYSTEM'),
    NULLIF(elem->>'deeplink', ''),
    CASE LOWER(COALESCE(elem->>'audience', 'all'))
        WHEN 'active' THEN 'ACTIVE'::"BroadcastAudience"
        WHEN 'area' THEN 'AREA'::"BroadcastAudience"
        WHEN 'users' THEN 'USERS'::"BroadcastAudience"
        ELSE 'ALL'::"BroadcastAudience"
    END,
    CASE
        WHEN elem->'audienceUserIds' IS NULL OR jsonb_typeof(elem->'audienceUserIds') <> 'array' THEN ARRAY[]::TEXT[]
        ELSE COALESCE(ARRAY(SELECT jsonb_array_elements_text(elem->'audienceUserIds')), ARRAY[]::TEXT[])
    END,
    CASE LOWER(COALESCE(elem->>'status', 'draft'))
        WHEN 'scheduled' THEN 'SCHEDULED'::"BroadcastCampaignStatus"
        WHEN 'sent' THEN 'SENT'::"BroadcastCampaignStatus"
        WHEN 'cancelled' THEN 'CANCELLED'::"BroadcastCampaignStatus"
        ELSE 'DRAFT'::"BroadcastCampaignStatus"
    END,
    NULLIF(elem->>'scheduledAt', '')::timestamptz,
    NULLIF(elem->>'sentAt', '')::timestamptz,
    NULLIF(elem->>'sentCount', '')::INTEGER,
    NULL
FROM "SystemConfig" sc,
    jsonb_array_elements(
        CASE
            WHEN sc."value" IS NULL OR btrim(sc."value") = '' THEN '[]'::jsonb
            WHEN jsonb_typeof(sc."value"::jsonb) = 'array' THEN sc."value"::jsonb
            ELSE '[]'::jsonb
        END
    ) AS elem
WHERE sc."key" = 'admin_broadcast_campaigns'
  AND elem->>'id' IS NOT NULL
  AND btrim(elem->>'id') <> ''
  AND elem->>'title' IS NOT NULL
  AND btrim(elem->>'title') <> ''
  AND elem->>'body' IS NOT NULL
  AND btrim(elem->>'body') <> ''
ON CONFLICT ("id") DO NOTHING;

DELETE FROM "SystemConfig" WHERE "key" = 'admin_broadcast_campaigns';
