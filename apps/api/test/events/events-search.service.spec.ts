/// <reference types="jest" />

import { BadRequestException } from '@nestjs/common';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { EventSearchDto } from '../../src/events/dto/event-search.dto';
import { EventsSearchQueryService } from '../../src/events/events-search-query.service';
import { EventsSearchService } from '../../src/events/events-search.service';
import { EventsMobileMapperService } from '../../src/events/events-mobile-mapper.service';
import { EventsRepository } from '../../src/events/events.repository';

function user(): AuthenticatedUser {
  return {
    userId: 'u1',
    email: 'u1@test.chisto.mk',
    phoneNumber: '+38970000000',
    role: 'USER' as never,
  };
}

describe('EventsSearchService', () => {
  let service: EventsSearchService;

  beforeEach(() => {
    const prisma = {
      $queryRaw: jest.fn().mockResolvedValue([]),
      cleanupEvent: { findMany: jest.fn().mockResolvedValue([]) },
    };
    const repo = { prisma, listRecurrenceSeriesEventsBatch: jest.fn().mockResolvedValue(new Map()) } as unknown as EventsRepository;
    const uploads = { signUrls: jest.fn(async (u: string[]) => u) };
    const mobileMapper = { toMobileEvent: jest.fn(async () => ({})) } as unknown as EventsMobileMapperService;
    const searchQuery = new EventsSearchQueryService(repo);
    service = new EventsSearchService(repo, uploads as never, mobileMapper, searchQuery);
  });

  describe('buildListSearchWhere', () => {
    it('returns null for empty or short q', () => {
      expect(service.buildListSearchWhere(undefined)).toBeNull();
      expect(service.buildListSearchWhere('')).toBeNull();
      expect(service.buildListSearchWhere(' a ')).toBeNull();
    });

    it('returns OR contains filter for 2+ chars', () => {
      const w = service.buildListSearchWhere('ab');
      expect(w).toEqual({
        OR: [
          { title: { contains: 'ab', mode: 'insensitive' } },
          { description: { contains: 'ab', mode: 'insensitive' } },
        ],
      });
    });
  });

  describe('search', () => {
    it('throws when status filter is invalid', async () => {
      const dto = Object.assign(new EventSearchDto(), { query: 'cleanup', status: 'not-a-real-status' });
      await expect(service.search(user(), dto)).rejects.toBeInstanceOf(BadRequestException);
    });

    it('throws when only one of nearLat/nearLng provided', async () => {
      const dto = Object.assign(new EventSearchDto(), { query: 'cleanup', nearLat: 42 });
      await expect(service.search(user(), dto)).rejects.toBeInstanceOf(BadRequestException);
    });
  });
});
