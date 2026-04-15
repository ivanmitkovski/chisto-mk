import { ApiProperty } from '@nestjs/swagger';
import { Role, UserStatus } from '../../prisma-client';

export class AuthUserDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  firstName!: string;

  @ApiProperty()
  lastName!: string;

  @ApiProperty()
  email!: string;

  @ApiProperty()
  phoneNumber!: string;

  @ApiProperty({ enum: Role })
  role!: Role;

  @ApiProperty({ enum: UserStatus })
  status!: UserStatus;

  @ApiProperty()
  isPhoneVerified!: boolean;

  @ApiProperty()
  pointsBalance!: number;

  @ApiProperty({
    nullable: true,
    description: 'Signed URL for the profile avatar, if set',
  })
  avatarUrl!: string | null;
}

export class AuthResponseDto {
  @ApiProperty({
    description: 'Short-lived JWT access token for API authentication',
  })
  accessToken!: string;

  @ApiProperty({
    description: 'Long-lived opaque refresh token for session renewal',
  })
  refreshToken!: string;

  @ApiProperty({ type: AuthUserDto })
  user!: AuthUserDto;
}
