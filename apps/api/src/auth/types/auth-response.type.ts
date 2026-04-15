import { Role, UserStatus } from '../../prisma-client';

export type AuthResponse = {
  accessToken: string;
  refreshToken: string;
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
    avatarUrl: string | null;
  };
};

export type AdminLogin2FAResponse = {
  requiresTotp: true;
  tempToken: string;
  expiresIn: number;
};

export type AdminLoginResponse = AuthResponse | AdminLogin2FAResponse;

export function is2FAResponse(r: AdminLoginResponse): r is AdminLogin2FAResponse {
  return 'requiresTotp' in r && r.requiresTotp === true;
}
