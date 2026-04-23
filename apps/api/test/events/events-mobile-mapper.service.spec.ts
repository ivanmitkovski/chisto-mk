/// <reference types="jest" />

import { CleanupEventStatus, EcoEventCategory, EcoEventDifficulty, EcoEventLifecycleStatus } from '../../src/prisma-client';
import { ReportsUploadService } from '../../src/reports/reports-upload.service';
import { EventsMobileMapperService } from '../../src/events/events-mobile-mapper.service';
import { EventsRepository } from '../../src/events/events.repository';

describe('EventsMobileMapperService', () => {
  it('maps a minimal loaded row to EventMobileResponseDto', async () => {
    const prisma = {
      cleanupEvent: { findMany: jest.fn() },
    };
    const eventsRepository = new EventsRepository(prisma as never);
    const uploads = {
      signUrls: jest.fn().mockImplementation(async (urls: string[]) => urls),
      getPublicUrlsForKeys: jest.fn((keys: string[]) => keys),
      signPrivateObjectKey: jest.fn().mockResolvedValue(null),
    } as unknown as ReportsUploadService;

    const mapper = new EventsMobileMapperService(eventsRepository, uploads);

    const row = {
      id: '00000000-0000-7000-8000-000000000001',
      title: 'T',
      description: 'D',
      category: EcoEventCategory.GENERAL_CLEANUP,
      status: CleanupEventStatus.APPROVED,
      siteId: '00000000-0000-7000-8000-000000000002',
      organizerId: '00000000-0000-7000-8000-000000000003',
      scheduledAt: new Date('2026-05-01T10:00:00.000Z'),
      endAt: null,
      lifecycleStatus: EcoEventLifecycleStatus.UPCOMING,
      participantCount: 0,
      maxParticipants: null,
      gear: ['trashBags'],
      scale: null,
      difficulty: EcoEventDifficulty.EASY,
      createdAt: new Date('2026-04-01T00:00:00.000Z'),
      afterImageKeys: [],
      checkInSessionId: null,
      checkInOpen: false,
      checkedInCount: 0,
      recurrenceRule: null,
      parentEventId: null,
      recurrenceIndex: null,
      participants: [],
      checkIns: [],
      liveMetric: null,
      routeSegments: [],
      evidencePhotos: [],
      site: {
        id: '00000000-0000-7000-8000-000000000002',
        address: 'Addr',
        description: null,
        latitude: 41.9,
        longitude: 21.4,
        reports: [],
      },
      organizer: {
        id: '00000000-0000-7000-8000-000000000003',
        firstName: 'A',
        lastName: 'B',
        avatarObjectKey: null,
      },
    } as never;

    const dto = await mapper.toMobileEvent(row, { siteDistanceKm: 1.25 });

    expect(dto.id).toBe('00000000-0000-7000-8000-000000000001');
    expect(dto.siteDistanceKm).toBe(1.25);
    expect(dto.gear).toEqual(['trashBags']);
  });
});
