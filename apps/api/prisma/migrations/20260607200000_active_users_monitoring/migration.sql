-- Active users monitoring: activity events, daily stats, alert rules, session metadata.

CREATE TYPE "UserActivityEventType" AS ENUM (
  'LOGIN',
  'LOGOUT',
  'APP_OPENED',
  'SCREEN_VIEW',
  'REPORT_CREATED',
  'REPORT_SUBMITTED',
  'EVENT_JOINED',
  'CHECK_IN'
);

CREATE TYPE "AdminAlertMetric" AS ENUM (
  'CONCURRENT',
  'TRAFFIC_SPIKE',
  'ERROR_RATE',
  'REPORT_ACTIVITY',
  'API_DEGRADATION'
);

CREATE TYPE "AdminAlertComparator" AS ENUM ('GT', 'GTE');

ALTER TABLE "UserSession" ADD COLUMN "lastSeenAt" TIMESTAMP(3);
ALTER TABLE "UserSession" ADD COLUMN "platform" "DevicePlatform";
ALTER TABLE "UserSession" ADD COLUMN "appVersion" TEXT;
ALTER TABLE "UserSession" ADD COLUMN "deviceModel" TEXT;
ALTER TABLE "UserSession" ADD COLUMN "osVersion" TEXT;
ALTER TABLE "UserSession" ADD COLUMN "country" TEXT;
ALTER TABLE "UserSession" ADD COLUMN "city" TEXT;

CREATE TABLE "UserActivityEvent" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "sessionId" TEXT,
  "deviceId" TEXT,
  "type" "UserActivityEventType" NOT NULL,
  "screen" TEXT,
  "metadata" JSONB,
  "platform" "DevicePlatform",
  "appVersion" TEXT,
  "occurredAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "UserActivityEvent_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "DailyActiveStat" (
  "id" TEXT NOT NULL,
  "date" DATE NOT NULL,
  "dau" INTEGER NOT NULL DEFAULT 0,
  "wau" INTEGER NOT NULL DEFAULT 0,
  "mau" INTEGER NOT NULL DEFAULT 0,
  "peakConcurrent" INTEGER NOT NULL DEFAULT 0,
  "avgConcurrent" DOUBLE PRECISION NOT NULL DEFAULT 0,
  "sessionsStarted" INTEGER NOT NULL DEFAULT 0,
  "reportsSubmitted" INTEGER NOT NULL DEFAULT 0,
  "newRegistrations" INTEGER NOT NULL DEFAULT 0,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "DailyActiveStat_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "AdminAlertRule" (
  "id" TEXT NOT NULL,
  "metric" "AdminAlertMetric" NOT NULL,
  "comparator" "AdminAlertComparator" NOT NULL DEFAULT 'GT',
  "threshold" DOUBLE PRECISION NOT NULL,
  "windowSeconds" INTEGER NOT NULL DEFAULT 300,
  "enabled" BOOLEAN NOT NULL DEFAULT true,
  "lastTriggeredAt" TIMESTAMP(3),
  "createdById" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "AdminAlertRule_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "DailyActiveStat_date_key" ON "DailyActiveStat"("date");
CREATE INDEX "UserActivityEvent_userId_occurredAt_idx" ON "UserActivityEvent"("userId", "occurredAt" DESC);
CREATE INDEX "UserActivityEvent_occurredAt_idx" ON "UserActivityEvent"("occurredAt" DESC);
CREATE INDEX "UserActivityEvent_type_occurredAt_idx" ON "UserActivityEvent"("type", "occurredAt" DESC);
CREATE INDEX "AdminAlertRule_enabled_idx" ON "AdminAlertRule"("enabled");
CREATE INDEX "AdminAlertRule_metric_idx" ON "AdminAlertRule"("metric");

ALTER TABLE "UserActivityEvent" ADD CONSTRAINT "UserActivityEvent_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "UserActivityEvent" ADD CONSTRAINT "UserActivityEvent_sessionId_fkey"
  FOREIGN KEY ("sessionId") REFERENCES "UserSession"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "AdminAlertRule" ADD CONSTRAINT "AdminAlertRule_createdById_fkey"
  FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
