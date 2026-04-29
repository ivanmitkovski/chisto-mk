import { Injectable } from '@nestjs/common';
import { FeedCandidateWithStage } from '../feed-v2.types';
import { PrismaService } from '../../../prisma/prisma.service';
import { CandidateRequestContext } from './candidate-generator';
import { toStageCandidate } from './candidate-mapper';

@Injectable()
export class GeoRetriever {
  constructor(private readonly prisma: PrismaService) {}

  async retrieve(context: CandidateRequestContext): Promise<FeedCandidateWithStage[]> {
    if (context.lat == null || context.lng == null) {
      return [];
    }
    const radiusKm = Math.max(1, context.radiusKm ?? 50);
    const radiusMeters = radiusKm * 1000;
    const metersPerDegreeLat = 111_320;
    const deltaLat = radiusMeters / metersPerDegreeLat;
    const metersPerDegreeLng = Math.cos((context.lat * Math.PI) / 180) * metersPerDegreeLat || metersPerDegreeLat;
    const deltaLng = radiusMeters / metersPerDegreeLng;
    const rows = await this.prisma.site.findMany({
      where: {
        ...(context.status ? { status: context.status } : {}),
        latitude: { gte: context.lat - deltaLat, lte: context.lat + deltaLat },
        longitude: { gte: context.lng - deltaLng, lte: context.lng + deltaLng },
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: Math.max(20, Math.min(200, context.limit ?? 120)),
      include: {
        reports: {
          orderBy: { createdAt: 'desc' },
          take: 1,
          select: { createdAt: true, category: true, reporterId: true },
        },
        _count: { select: { reports: true } },
      },
    });
    return rows.map((row) => toStageCandidate(row, 'geo', 0.92));
  }
}
