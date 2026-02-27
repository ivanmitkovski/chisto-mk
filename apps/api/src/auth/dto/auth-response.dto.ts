import { ApiProperty } from '@nestjs/swagger';
import { Role, UserStatus } from '@prisma/client';

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
}

export class AuthResponseDto {
  @ApiProperty({
    description: 'JWT access token to authenticate subsequent requests',
  })
  accessToken!: string;

  @ApiProperty({ type: AuthUserDto })
  user!: AuthUserDto;
}

