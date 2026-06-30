import { BadRequestException } from '@nestjs/common';

import { isWithinMacedonia } from '../../common/geo/macedonia-bounds';

/** Rejects home-location coordinates outside Macedonia (shared bbox). */
export function assertHomeLocationInMacedonia(latitude: number, longitude: number): void {
  if (!isWithinMacedonia(latitude, longitude)) {
    throw new BadRequestException({
      code: 'VALIDATION_ERROR',
      message: 'Home location must be within Macedonia',
    });
  }
}
