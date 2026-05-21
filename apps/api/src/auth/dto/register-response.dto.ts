import { ApiProperty } from '@nestjs/swagger';

export class RegisterResponseDto {
  @ApiProperty()
  userId!: string;

  @ApiProperty({ example: '+38970123456' })
  phoneNumber!: string;

  @ApiProperty({ example: true })
  requiresPhoneVerification!: true;

  @ApiProperty({ example: 600, description: 'OTP validity in seconds' })
  otpExpiresIn!: number;
}
