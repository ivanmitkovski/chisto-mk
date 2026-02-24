import { Role, UserStatus } from '@prisma/client';

export type AuthResponse = {
  accessToken: string;
  user: {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
    phoneNumber: string;
    role: Role;
    status: UserStatus;
    isPhoneVerified: boolean;
    pointsBalance: number;
  };
};
