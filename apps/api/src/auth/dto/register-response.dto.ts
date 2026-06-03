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

  @ApiProperty({ required: false, description: 'Development-only OTP when OTP_DEV_RETURN_CODE is enabled' })
  devCode?: string;
}
