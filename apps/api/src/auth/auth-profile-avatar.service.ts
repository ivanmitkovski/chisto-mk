import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { UserStatus } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { ReportsUploadService } from '../reports/reports-upload.service';

@Injectable()
export class AuthProfileAvatarService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsUploadService: ReportsUploadService,
  ) {}

  async uploadAvatar(
    userId: string,
    file: Express.Multer.File | undefined,
  ): Promise<{ avatarUrl: string | null }> {
    const user = await this.assertActiveUser(userId);
    if (!file) {
      throw new BadRequestException({
        code: 'AVATAR_FILE_REQUIRED',
        message: 'Avatar image file is required.',
      });
    }
    const nextKey = await this.reportsUploadService.uploadProfileAvatar(userId, file);
    await this.prisma.user.update({
      where: { id: userId },
      data: { avatarObjectKey: nextKey, avatarUpdatedAt: new Date() },
    });
    const signedUrl = await this.reportsUploadService.signPrivateObjectKey(nextKey);
    if (user.avatarObjectKey) {
      void this.reportsUploadService.deleteObjectByKey(user.avatarObjectKey).catch(() => {});
    }
    return { avatarUrl: signedUrl };
  }

  async removeAvatar(userId: string): Promise<void> {
    const user = await this.assertActiveUser(userId);
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        avatarObjectKey: null,
        avatarUpdatedAt: new Date(),
      },
    });
    if (user.avatarObjectKey) {
      void this.reportsUploadService.deleteObjectByKey(user.avatarObjectKey).catch(() => {});
    }
  }

  private async assertActiveUser(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, status: true, avatarObjectKey: true },
    });
    if (!user) {
      throw new UnauthorizedException({
        code: 'INVALID_TOKEN_USER',
        message: 'User not found',
      });
    }
    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException({
        code: 'ACCOUNT_NOT_ACTIVE',
        message: 'Account is not active',
      });
    }
    return user;
  }
}
