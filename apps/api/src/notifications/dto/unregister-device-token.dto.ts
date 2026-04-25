import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class UnregisterDeviceTokenDto {
  @ApiProperty({ description: 'FCM device token to revoke (body param avoids logging token in URL paths)' })
  @IsString()
  @MinLength(10)
  token!: string;
}
