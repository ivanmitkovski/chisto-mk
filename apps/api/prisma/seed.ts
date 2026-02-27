import { PrismaClient, Role, SiteStatus, ReportStatus } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();
const SALT_ROUNDS = 12;

async function main() {
  // Danger: this is a development-only seed. It clears all tables first.
  await prisma.reportCoReporter.deleteMany();
  await prisma.adminNotification.deleteMany();
  await prisma.pointTransaction.deleteMany();
  await prisma.cleanupEvent.deleteMany();
  await prisma.report.deleteMany();
  await prisma.site.deleteMany();
  await prisma.user.deleteMany();

  const passwordHash = await bcrypt.hash('Password123!', SALT_ROUNDS);

  const admin = await prisma.user.create({
    data: {
      firstName: 'Admin',
      lastName: 'User',
      email: 'admin@chisto.mk',
      phoneNumber: '+38970000000',
      passwordHash,
      role: Role.ADMIN,
      status: 'ACTIVE',
      isPhoneVerified: true,
    },
  });

  const reporterA = await prisma.user.create({
    data: {
      firstName: 'Ana',
      lastName: 'Reporter',
      email: 'ana@example.com',
      phoneNumber: '+38970000001',
      passwordHash,
      role: Role.USER,
      status: 'ACTIVE',
      isPhoneVerified: true,
    },
  });

  const reporterB = await prisma.user.create({
    data: {
      firstName: 'Boris',
      lastName: 'Reporter',
      email: 'boris@example.com',
      phoneNumber: '+38970000002',
      passwordHash,
      role: Role.USER,
      status: 'ACTIVE',
      isPhoneVerified: false,
    },
  });

  const riversideSite = await prisma.site.create({
    data: {
      latitude: 41.9981,
      longitude: 21.4254,
      description: 'Illegal dumping near the riverbank',
      status: SiteStatus.REPORTED,
    },
  });

  const parkSite = await prisma.site.create({
    data: {
      latitude: 41.999,
      longitude: 21.43,
      description: 'Overflowing bins near city park',
      status: SiteStatus.REPORTED,
    },
  });

  const primaryReport = await prisma.report.create({
    data: {
      siteId: riversideSite.id,
      reporterId: reporterA.id,
      description: 'Large pile of mixed waste next to the riverbank.',
      mediaUrls: [],
      status: ReportStatus.NEW,
    },
  });

  const duplicateReport = await prisma.report.create({
    data: {
      siteId: riversideSite.id,
      reporterId: reporterB.id,
      description: 'Same trash spot reported from different user.',
      mediaUrls: [],
      status: ReportStatus.NEW,
      potentialDuplicateOfId: primaryReport.id,
    },
  });

  await prisma.reportCoReporter.create({
    data: {
      reportId: primaryReport.id,
      userId: reporterB.id,
    },
  });

  const parkReport = await prisma.report.create({
    data: {
      siteId: parkSite.id,
      reporterId: reporterA.id,
      description: 'Bins overflowing after weekend event.',
      mediaUrls: [],
      status: ReportStatus.IN_REVIEW,
      moderatedAt: new Date(),
      moderationReason: 'Awaiting cleanup scheduling.',
      moderatedById: admin.id,
    },
  });

  await prisma.cleanupEvent.create({
    data: {
      siteId: riversideSite.id,
      scheduledAt: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
      completedAt: null,
      organizerId: admin.id,
      participantCount: 0,
    },
  });

  await prisma.cleanupEvent.create({
    data: {
      siteId: parkSite.id,
      scheduledAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
      completedAt: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000),
      organizerId: admin.id,
      participantCount: 12,
    },
  });

  await prisma.pointTransaction.createMany({
    data: [
      {
        userId: reporterA.id,
        delta: 50,
        balanceAfter: 50,
        reasonCode: 'REPORT_SUBMITTED',
        referenceType: 'Report',
        referenceId: primaryReport.id,
      },
      {
        userId: reporterA.id,
        delta: 25,
        balanceAfter: 75,
        reasonCode: 'REPORT_APPROVED',
        referenceType: 'Report',
        referenceId: parkReport.id,
      },
      {
        userId: reporterB.id,
        delta: 25,
        balanceAfter: 25,
        reasonCode: 'CO_REPORTER',
        referenceType: 'Report',
        referenceId: duplicateReport.id,
      },
    ],
  });

  await prisma.adminNotification.createMany({
    data: [
      {
        userId: admin.id,
        title: 'New report waiting for review',
        message: `Report ${primaryReport.id} has been submitted near the riverbank.`,
        timeLabel: 'Just now',
        tone: 'info',
        category: 'reports',
        isUnread: true,
        href: `/dashboard/reports?reportId=${primaryReport.id}`,
      },
      {
        userId: admin.id,
        title: 'Maybe duplicate report detected',
        message: 'A report near the riverbank looks similar to an existing one.',
        timeLabel: '2 min ago',
        tone: 'warning',
        category: 'reports',
        isUnread: true,
        href: `/dashboard/reports?reportId=${duplicateReport.id}`,
      },
      {
        userId: admin.id,
        title: 'Cleanup event completed',
        message: 'A cleanup event at the city park has been marked as completed.',
        timeLabel: 'Yesterday',
        tone: 'success',
        category: 'system',
        isUnread: false,
        href: `/dashboard/sites`,
      },
    ],
  });
}

main()
  .catch((error) => {
    // eslint-disable-next-line no-console
    console.error('Seeding failed:', error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

