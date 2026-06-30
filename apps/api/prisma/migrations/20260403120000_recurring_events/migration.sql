-- AlterTable: add recurring-events fields to CleanupEvent
ALTER TABLE "CleanupEvent"
  ADD COLUMN "recurrenceRule"  TEXT,
  ADD COLUMN "parentEventId"   TEXT,
  ADD COLUMN "recurrenceIndex" INTEGER;

-- AddForeignKey for self-referencing series relation
ALTER TABLE "CleanupEvent"
  ADD CONSTRAINT "CleanupEvent_parentEventId_fkey"
  FOREIGN KEY ("parentEventId")
  REFERENCES "CleanupEvent"("id")
  ON DELETE SET NULL
  ON UPDATE CASCADE;

-- CreateIndex on parentEventId for efficient series queries
CREATE INDEX "CleanupEvent_parentEventId_idx" ON "CleanupEvent"("parentEventId");
