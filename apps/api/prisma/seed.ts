import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import {
  PrismaClient,
  Role,
  SiteStatus,
  ReportStatus,
  CleanupEventStatus,
  EcoEventLifecycleStatus,
  EcoEventCategory,
  EcoCleanupScale,
  EcoEventDifficulty,
} from '../src/prisma-client';
import * as bcrypt from 'bcrypt';

function connectionStringWithNoVerify(url: string): string {
  const noVerify = 'sslmode=no-verify';
  if (url.includes('sslmode=')) return url.replace(/sslmode=[^&]*/i, noVerify);
  return `${url}${url.includes('?') ? '&' : '?'}${noVerify}`;
}

const adapter = new PrismaPg({
  connectionString: connectionStringWithNoVerify(process.env.DATABASE_URL!),
});
const prisma = new PrismaClient({ adapter });
const SALT_ROUNDS = 12;

/** Stable session id for the seeded "live check-in" event (matches QR `s` claim when you mint tokens). */
const SEED_LIVE_CHECK_IN_SESSION_ID = 'a0000000-0000-4000-8000-000000000001';

async function wipe() {
  await prisma.eventCheckInRedemption.deleteMany();
  await prisma.eventCheckIn.deleteMany();
  await prisma.eventParticipant.deleteMany();
  await prisma.cleanupEvent.deleteMany();
  await prisma.reportCoReporter.deleteMany();
  await prisma.adminNotification.deleteMany();
  await prisma.pointTransaction.deleteMany();
  await prisma.report.deleteMany();
  await prisma.site.deleteMany();
  await prisma.user.deleteMany();
}

async function main() {
  await wipe();

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

  /** Regular user who owns several seeded events (creator / organizer flows). */
  const eventOrganizer = await prisma.user.create({
    data: {
      firstName: 'Elena',
      lastName: 'Organizer',
      email: 'eventorganizer@example.com',
      phoneNumber: '+38970000010',
      passwordHash,
      role: Role.USER,
      status: 'ACTIVE',
      isPhoneVerified: true,
    },
  });

  const participant1 = await prisma.user.create({
    data: {
      firstName: 'Petar',
      lastName: 'Volunteer',
      email: 'eventparticipant1@example.com',
      phoneNumber: '+38970000011',
      passwordHash,
      role: Role.USER,
      status: 'ACTIVE',
      isPhoneVerified: true,
    },
  });

  const participant2 = await prisma.user.create({
    data: {
      firstName: 'Marija',
      lastName: 'Volunteer',
      email: 'eventparticipant2@example.com',
      phoneNumber: '+38970000012',
      passwordHash,
      role: Role.USER,
      status: 'ACTIVE',
      isPhoneVerified: true,
    },
  });

  const participant3 = await prisma.user.create({
    data: {
      firstName: 'Stefan',
      lastName: 'Volunteer',
      email: 'eventparticipant3@example.com',
      phoneNumber: '+38970000013',
      passwordHash,
      role: Role.USER,
      status: 'ACTIVE',
      isPhoneVerified: true,
    },
  });

  const riversideSite = await prisma.site.create({
    data: {
      latitude: 41.9981,
      longitude: 21.4254,
      address: 'Vardar riverbank, Skopje',
      description: 'Illegal dumping near the riverbank',
      status: SiteStatus.REPORTED,
    },
  });

  const parkSite = await prisma.site.create({
    data: {
      latitude: 41.999,
      longitude: 21.43,
      address: 'City Park, Skopje',
      description: 'Overflowing bins near city park',
      status: SiteStatus.VERIFIED,
    },
  });

  const forestSite = await prisma.site.create({
    data: {
      latitude: 41.985,
      longitude: 21.41,
      address: 'Vodno trailhead',
      description: 'Forest trail litter hotspot',
      status: SiteStatus.CLEANUP_SCHEDULED,
    },
  });

  const primaryReport = await prisma.report.create({
    data: {
      siteId: riversideSite.id,
      reporterId: reporterA.id,
      title: 'Mixed waste by the riverbank',
      description: 'Large pile of mixed waste next to the riverbank.',
      mediaUrls: ['https://picsum.photos/seed/chisto-river/800/600'],
      status: ReportStatus.NEW,
    },
  });

  const duplicateReport = await prisma.report.create({
    data: {
      siteId: riversideSite.id,
      reporterId: reporterB.id,
      title: 'Same trash spot — co-report',
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
      reportedAt: duplicateReport.createdAt,
    },
  });

  const parkReport = await prisma.report.create({
    data: {
      siteId: parkSite.id,
      reporterId: reporterA.id,
      title: 'Overflowing bins after weekend',
      description: 'Bins overflowing after weekend event.',
      mediaUrls: [],
      status: ReportStatus.IN_REVIEW,
      moderatedAt: new Date(),
      moderationReason: 'Awaiting cleanup scheduling.',
      moderatedById: admin.id,
    },
  });

  const now = Date.now();
  const in2d = new Date(now + 2 * 24 * 60 * 60 * 1000);
  const in7d = new Date(now + 7 * 24 * 60 * 60 * 1000);
  const in1h = new Date(now + 60 * 60 * 1000);
  const started1hAgo = new Date(now - 60 * 60 * 1000);
  const endedYesterday = new Date(now - 24 * 60 * 60 * 1000);

  // --- Events: moderation, lifecycle, participants, check-ins ---

  const pendingEvent = await prisma.cleanupEvent.create({
    data: {
      siteId: riversideSite.id,
      title: '[SEED] Pending cleanup — awaits approval',
      description:
        'User-created event still in PENDING. Visible to organizer only until approved.',
      category: EcoEventCategory.RIVER_AND_LAKE,
      scheduledAt: in7d,
      endAt: new Date(in7d.getTime() + 3 * 60 * 60 * 1000),
      status: CleanupEventStatus.PENDING,
      lifecycleStatus: EcoEventLifecycleStatus.UPCOMING,
      organizerId: eventOrganizer.id,
      participantCount: 0,
      gear: ['gloves', 'bags'],
      scale: EcoCleanupScale.MEDIUM,
      difficulty: EcoEventDifficulty.MODERATE,
      maxParticipants: 40,
    },
  });

  const upcomingEvent = await prisma.cleanupEvent.create({
    data: {
      siteId: parkSite.id,
      title: '[SEED] Park cleanup — upcoming',
      description: 'Approved public event. Join as participant1–3 to test RSVP, reminders, feed.',
      category: EcoEventCategory.GENERAL_CLEANUP,
      scheduledAt: in2d,
      endAt: new Date(in2d.getTime() + 4 * 60 * 60 * 1000),
      status: CleanupEventStatus.APPROVED,
      lifecycleStatus: EcoEventLifecycleStatus.UPCOMING,
      organizerId: eventOrganizer.id,
      participantCount: 3,
      gear: ['gloves', 'bags', 'high_vis'],
      scale: EcoCleanupScale.LARGE,
      difficulty: EcoEventDifficulty.EASY,
      maxParticipants: 25,
    },
  });

  await prisma.eventParticipant.createMany({
    data: [
      {
        eventId: upcomingEvent.id,
        userId: participant1.id,
        reminderEnabled: true,
        reminderAt: new Date(now + 24 * 60 * 60 * 1000),
      },
      { eventId: upcomingEvent.id, userId: participant2.id },
      { eventId: upcomingEvent.id, userId: participant3.id },
    ],
  });

  const liveCheckInEvent = await prisma.cleanupEvent.create({
    data: {
      siteId: forestSite.id,
      title: '[SEED] Forest sweep — check-in OPEN',
      description:
        'IN_PROGRESS + checkInOpen. Log in as eventorganizer to manage QR; join as participant3 and scan to test redeem (participant1–2 already checked in in seed).',
      category: EcoEventCategory.TREE_AND_GREEN,
      scheduledAt: started1hAgo,
      endAt: in1h,
      status: CleanupEventStatus.APPROVED,
      lifecycleStatus: EcoEventLifecycleStatus.IN_PROGRESS,
      organizerId: eventOrganizer.id,
      participantCount: 4,
      checkedInCount: 4,
      checkInOpen: true,
      checkInSessionId: SEED_LIVE_CHECK_IN_SESSION_ID,
      gear: ['gloves'],
      scale: EcoCleanupScale.SMALL,
      difficulty: EcoEventDifficulty.EASY,
      maxParticipants: 30,
    },
  });

  await prisma.eventParticipant.createMany({
    data: [
      { eventId: liveCheckInEvent.id, userId: reporterA.id },
      { eventId: liveCheckInEvent.id, userId: reporterB.id },
      { eventId: liveCheckInEvent.id, userId: participant1.id },
      { eventId: liveCheckInEvent.id, userId: participant3.id },
    ],
  });

  await prisma.eventCheckIn.createMany({
    data: [
      {
        eventId: liveCheckInEvent.id,
        dedupeKey: `u:${reporterA.id}`,
        userId: reporterA.id,
      },
      {
        eventId: liveCheckInEvent.id,
        dedupeKey: `u:${reporterB.id}`,
        userId: reporterB.id,
      },
      {
        eventId: liveCheckInEvent.id,
        dedupeKey: `u:${participant1.id}`,
        userId: participant1.id,
      },
      {
        eventId: liveCheckInEvent.id,
        dedupeKey: 'g:walkin_seed_volunteer',
        userId: null,
        guestDisplayName: 'Walk-in volunteer (seed)',
      },
    ],
  });

  const completedEvent = await prisma.cleanupEvent.create({
    data: {
      siteId: parkSite.id,
      title: '[SEED] Park weekend — completed',
      description: 'Past event with after photos (object keys are placeholders).',
      category: EcoEventCategory.RECYCLING_DRIVE,
      scheduledAt: new Date(now - 5 * 24 * 60 * 60 * 1000),
      endAt: endedYesterday,
      completedAt: endedYesterday,
      status: CleanupEventStatus.APPROVED,
      lifecycleStatus: EcoEventLifecycleStatus.COMPLETED,
      organizerId: admin.id,
      participantCount: 2,
      gear: ['gloves', 'bags'],
      afterImageKeys: ['seed/events/park-after-1.jpg', 'seed/events/park-after-2.jpg'],
    },
  });

  await prisma.eventParticipant.createMany({
    data: [
      { eventId: completedEvent.id, userId: reporterA.id },
      { eventId: completedEvent.id, userId: participant2.id },
    ],
  });

  const declinedEvent = await prisma.cleanupEvent.create({
    data: {
      siteId: riversideSite.id,
      title: '[SEED] Declined event (organizer only)',
      description: 'Moderation declined. Still visible to the organizer for history.',
      category: EcoEventCategory.OTHER,
      scheduledAt: in7d,
      status: CleanupEventStatus.DECLINED,
      lifecycleStatus: EcoEventLifecycleStatus.UPCOMING,
      organizerId: eventOrganizer.id,
      participantCount: 0,
    },
  });

  const cancelledEvent = await prisma.cleanupEvent.create({
    data: {
      siteId: forestSite.id,
      title: '[SEED] Cancelled approved event',
      description: 'Was approved then cancelled — tests cancelled lifecycle in the app.',
      category: EcoEventCategory.AWARENESS_AND_EDUCATION,
      scheduledAt: new Date(now + 3 * 24 * 60 * 60 * 1000),
      status: CleanupEventStatus.APPROVED,
      lifecycleStatus: EcoEventLifecycleStatus.CANCELLED,
      organizerId: eventOrganizer.id,
      participantCount: 1,
    },
  });

  await prisma.eventParticipant.create({
    data: {
      eventId: cancelledEvent.id,
      userId: participant1.id,
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

  const seedNow = Date.now();
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
        createdAt: new Date(seedNow - 45_000),
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
        createdAt: new Date(seedNow - 8 * 60 * 60 * 1000),
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
        createdAt: new Date(seedNow - 30 * 60 * 60 * 1000),
      },
    ],
  });

  printEventSeedSummary({
    password: 'Password123!',
    admin,
    reporterA,
    reporterB,
    eventOrganizer,
    participant1,
    participant2,
    participant3,
    pendingEvent,
    upcomingEvent,
    liveCheckInEvent,
    completedEvent,
    declinedEvent,
    cancelledEvent,
  });
}

function printEventSeedSummary(args: {
  password: string;
  admin: { email: string; phoneNumber: string };
  reporterA: { email: string; phoneNumber: string };
  reporterB: { email: string; phoneNumber: string };
  eventOrganizer: { email: string; phoneNumber: string; id: string };
  participant1: { email: string; phoneNumber: string; id: string };
  participant2: { email: string; phoneNumber: string; id: string };
  participant3: { email: string; phoneNumber: string; id: string };
  pendingEvent: { id: string; title: string };
  upcomingEvent: { id: string; title: string };
  liveCheckInEvent: { id: string; title: string };
  completedEvent: { id: string; title: string };
  declinedEvent: { id: string; title: string };
  cancelledEvent: { id: string; title: string };
}) {
  const {
    password,
    admin,
    reporterA,
    reporterB,
    eventOrganizer,
    participant1,
    participant2,
    participant3,
    pendingEvent,
    upcomingEvent,
    liveCheckInEvent,
    completedEvent,
    declinedEvent,
    cancelledEvent,
  } = args;

  console.log(`
╔══════════════════════════════════════════════════════════════════════════════╗
║ Chisto.mk — database seed (reports + events QA)                               ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ Password for every seeded user: ${password.padEnd(42)}║
╠══════════════════════════════════════════════════════════════════════════════╣
║ ROLES                                                                        ║
║ • Admin:        ${admin.email} / ${admin.phoneNumber}
║ • Reporter A:   ${reporterA.email} / ${reporterA.phoneNumber}
║ • Reporter B:   ${reporterB.email} / ${reporterB.phoneNumber}
║ • Organizer:    ${eventOrganizer.email} / ${eventOrganizer.phoneNumber}  (creator flows)
║ • Participant 1:${participant1.email} / ${participant1.phoneNumber}
║ • Participant 2:${participant2.email} / ${participant2.phoneNumber}
║ • Participant 3:${participant3.email} / ${participant3.phoneNumber}
╠══════════════════════════════════════════════════════════════════════════════╣
║ EVENT IDS (use in API/mobile debugging)                                      ║
║ • PENDING (organizer-only until approved):                                   ║
║   ${pendingEvent.id}
║   "${pendingEvent.title}"
║ • APPROVED UPCOMING (+ participants + reminder on p1):                       ║
║   ${upcomingEvent.id}
║   "${upcomingEvent.title}"
║ • APPROVED IN_PROGRESS, check-in OPEN (session id for QR \`s\` claim):        ║
║   ${liveCheckInEvent.id}
║   "${liveCheckInEvent.title}"
║   checkInSessionId = ${SEED_LIVE_CHECK_IN_SESSION_ID}
║   Joined: Ana, Boris, participant1, participant3. Checked in: Ana, Boris,   ║
║   participant1 + walk-in guest row. participant3 NOT checked in → QR redeem. ║
║ • COMPLETED (after photos):                                                  ║
║   ${completedEvent.id}
║ • DECLINED (visible to organizer):                                           ║
║   ${declinedEvent.id}
║ • CANCELLED lifecycle:                                                       ║
║   ${cancelledEvent.id}
╚══════════════════════════════════════════════════════════════════════════════╝
`);
}

main()
  .catch((error) => {
    console.error('Seeding failed:', error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
