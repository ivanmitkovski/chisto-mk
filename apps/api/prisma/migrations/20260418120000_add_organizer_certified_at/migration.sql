-- AlterTable: add nullable organizer certification timestamp
ALTER TABLE "User" ADD COLUMN "organizerCertifiedAt" TIMESTAMP(3);
