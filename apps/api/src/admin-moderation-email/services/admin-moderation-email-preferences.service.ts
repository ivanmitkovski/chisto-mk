import { Injectable } from '@nestjs/common';
import { AdminModerationCategory, Role } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { roleHasPermission } from '../../auth/constants/admin-permissions';
import {
  ALL_ADMIN_MODERATION_CATEGORIES,
  CATEGORY_VIEW_PERMISSION,
} from '../constants/admin-moderation-email.constants';

export type ModerationEmailPreferenceRow = {
  category: AdminModerationCategory;
  enabled: boolean;
  source: 'default' | 'explicit';
};

@Injectable()
export class AdminModerationEmailPreferencesService {
  constructor(private readonly prisma: PrismaService) {}

  async listForUser(userId: string, role: Role): Promise<ModerationEmailPreferenceRow[]> {
    const explicit = await this.prisma.adminEmailPreference.findMany({
      where: { userId },
    });
    const byCategory = new Map(explicit.map((r) => [r.category, r.enabled]));

    return ALL_ADMIN_MODERATION_CATEGORIES.map((category) => {
      if (byCategory.has(category)) {
        return {
          category,
          enabled: byCategory.get(category) ?? false,
          source: 'explicit' as const,
        };
      }
      return {
        category,
        enabled: roleHasPermission(role, CATEGORY_VIEW_PERMISSION[category]),
        source: 'default' as const,
      };
    });
  }

  async isEnabledForUser(
    userId: string,
    role: Role,
    category: AdminModerationCategory,
  ): Promise<boolean> {
    const row = await this.prisma.adminEmailPreference.findUnique({
      where: { userId_category: { userId, category } },
      select: { enabled: true },
    });
    if (row != null) {
      return row.enabled;
    }
    return roleHasPermission(role, CATEGORY_VIEW_PERMISSION[category]);
  }

  async setPreference(
    userId: string,
    category: AdminModerationCategory,
    enabled: boolean,
  ): Promise<void> {
    await this.prisma.adminEmailPreference.upsert({
      where: { userId_category: { userId, category } },
      create: { userId, category, enabled },
      update: { enabled },
    });
  }

  async disableFromUnsubscribe(userId: string, category: AdminModerationCategory): Promise<void> {
    await this.setPreference(userId, category, false);
  }
}
