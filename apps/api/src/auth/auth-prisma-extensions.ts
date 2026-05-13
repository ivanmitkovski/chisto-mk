import type { PrismaService } from '../prisma/prisma.service';

/** Prisma client extended with optional `loginFailure` model (migration-gated in some envs). */
export type PrismaWithLoginFailure = PrismaService & {
  loginFailure: {
    findUnique: (args: {
      where: { phoneNumber: string };
    }) => Promise<{ attemptCount: number; firstFailedAt: Date } | null>;
    deleteMany: (args: { where: { phoneNumber: string } }) => Promise<unknown>;
    create: (args: {
      data: { phoneNumber: string; firstFailedAt: Date; attemptCount: number };
    }) => Promise<unknown>;
    update: (args: {
      where: { phoneNumber: string };
      data: { firstFailedAt?: Date; attemptCount: number };
    }) => Promise<unknown>;
  };
};
