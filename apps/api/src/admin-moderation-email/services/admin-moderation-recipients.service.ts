import { Injectable } from '@nestjs/common';
import { AdminModerationCategory, Role, UserStatus } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { EmailSendEligibilityService } from '../../email/services/email-send-eligibility.service';
import { roleHasPermission } from '../../auth/constants/admin-permissions';
import { CATEGORY_VIEW_PERMISSION } from '../constants/admin-moderation-email.constants';
import { AdminModerationEmailPreferencesService } from './admin-moderation-email-preferences.service';

const STAFF_ROLES: Role[] = [Role.SUPPORT, Role.ADMIN, Role.SUPER_ADMIN];
const MAX_STAFF = 200;

export type ModerationEmailRecipient = {
  userId: string;
  email: string;
  firstName: string;
  role: Role;
};

@Injectable()
export class AdminModerationRecipientsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly preferences: AdminModerationEmailPreferencesService,
    private readonly eligibility: EmailSendEligibilityService,
  ) {}

  async resolveForCategory(category: AdminModerationCategory): Promise<ModerationEmailRecipient[]> {
    const permission = CATEGORY_VIEW_PERMISSION[category];
    const staff = await this.prisma.user.findMany({
      where: { role: { in: STAFF_ROLES }, status: UserStatus.ACTIVE },
      select: { id: true, email: true, firstName: true, role: true },
      take: MAX_STAFF,
    });

    const recipients: ModerationEmailRecipient[] = [];
    for (const user of staff) {
      if (!roleHasPermission(user.role, permission)) {
        continue;
      }
      const enabled = await this.preferences.isEnabledForUser(user.id, user.role, category);
      if (!enabled) {
        continue;
      }
      if (!(await this.eligibility.canSendToAddress(user.email))) {
        continue;
      }
      recipients.push({
        userId: user.id,
        email: user.email,
        firstName: user.firstName,
        role: user.role,
      });
    }
    return recipients;
  }
}
