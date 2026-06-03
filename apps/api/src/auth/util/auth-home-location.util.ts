import { BadRequestException } from '@nestjs/common';

/** Rough bounding box for North Macedonia (matches mobile onboarding map). */
export function assertHomeLocationInMacedonia(latitude: number, longitude: number): void {
  const inMk =
    latitude >= 40.8 &&
    latitude <= 42.4 &&
    longitude >= 20.4 &&
    longitude <= 23.1;
  if (!inMk) {
    throw new BadRequestException({
      code: 'VALIDATION_ERROR',
      message: 'Home location must be within North Macedonia',
    });
  }
}
