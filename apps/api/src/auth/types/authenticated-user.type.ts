import { Role } from '@prisma/client';

export type AuthenticatedUser = {
  userId: string;
  email: string;
  phoneNumber: string;
  role: Role;
};
