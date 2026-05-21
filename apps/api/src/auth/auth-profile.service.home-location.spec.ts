import { BadRequestException } from '@nestjs/common';
import { AuthProfileService } from './auth-profile.service';
import { assertHomeLocationInMacedonia } from './auth-home-location.util';

describe('assertHomeLocationInMacedonia', () => {
  it('accepts coordinates inside MK', () => {
    expect(() => assertHomeLocationInMacedonia(41.99, 21.43)).not.toThrow();
  });

  it('rejects coordinates outside MK', () => {
    expect(() => assertHomeLocationInMacedonia(52.52, 13.4)).toThrow(
      BadRequestException,
    );
  });
});

describe('AuthProfileService.updateHomeLocation', () => {
  it('is defined on service', () => {
    expect(AuthProfileService.prototype.updateHomeLocation).toBeDefined();
  });
});
