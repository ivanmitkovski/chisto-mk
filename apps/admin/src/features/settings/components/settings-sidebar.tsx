'use client';

import { useTranslations } from 'next-intl';
import { Icon } from '@/components/ui';
import { SIDEBAR_GROUPS, type SectionId } from '@/features/settings/config/settings-sections';
import { usePermissions } from '@/lib/auth/rbac';
import { ADMIN_PERMISSIONS, type AdminPermission } from '@/lib/auth/rbac/permissions';
import sidebarStyles from './settings-sidebar.module.css';

type SettingsSidebarProps = {
  section: SectionId;
  onSectionChange: (section: SectionId) => void;
};

const SECTION_PERMISSIONS: Partial<Record<SectionId, AdminPermission>> = {
  environment: ADMIN_PERMISSIONS['config:write'],
  featureFlags: ADMIN_PERMISSIONS['feature-flags:read'],
};

export function SettingsSidebar({ section, onSectionChange }: SettingsSidebarProps) {
  const t = useTranslations('settings');
  const { can } = usePermissions();

  return (
    <nav className={sidebarStyles.sidebar} aria-label={t('sidebarAria')}>
      {SIDEBAR_GROUPS.map((group) => {
        const visibleItems = group.items.filter((item) => {
          const required = SECTION_PERMISSIONS[item.id];
          return required ? can(required) : true;
        });
        if (visibleItems.length === 0) return null;

        return (
          <div key={group.labelKey} className={sidebarStyles.sidebarSection}>
            <span className={sidebarStyles.sidebarSectionLabel}>{t(group.labelKey)}</span>
            <div className={sidebarStyles.sidebarItems}>
              {visibleItems.map((s) => (
                <button
                  key={s.id}
                  type="button"
                  className={`${sidebarStyles.sidebarItem} ${section === s.id ? sidebarStyles.sidebarItemActive : ''}`}
                  onClick={() => onSectionChange(s.id)}
                  aria-current={section === s.id ? 'true' : undefined}
                >
                  <Icon name={s.icon} size={18} />
                  <span>{t(s.labelKey)}</span>
                </button>
              ))}
            </div>
          </div>
        );
      })}
    </nav>
  );
}
