import { NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

export async function assertSiteExists(prisma: PrismaService, siteId: string): Promise<void> {
  const site = await prisma.site.findUnique({
    where: { id: siteId },
    select: { id: true },
  });
  if (!site) {
    throw new NotFoundException({
      code: 'SITE_NOT_FOUND',
      message: `Site with id '${siteId}' was not found`,
    });
  }
}
