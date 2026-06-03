import { BadRequestException } from '@nestjs/common';

/** Feed list geo filter requires both coordinates when either is present. */
export function assertFeedGeoPairComplete(query: { lat?: number | null; lng?: number | null }): void {
  if ((query.lat != null) !== (query.lng != null)) {
    throw new BadRequestException({
      code: 'INVALID_GEO_QUERY',
      message: 'Both lat and lng must be provided together.',
    });
  }
}
