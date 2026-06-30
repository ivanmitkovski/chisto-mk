import { PrismaService } from '../../../src/prisma/prisma.service';

export async function deleteUsersByEmailPrefix(prisma: PrismaService, prefix: string): Promise<void> {
  await prisma.user.deleteMany({
    where: { email: { startsWith: prefix } },
  });
}
