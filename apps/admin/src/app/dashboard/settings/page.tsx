import { AdminShell } from '@/features/admin-shell';
import { SettingsProfile } from '@/features/settings';

export default function SettingsPage() {
  return (
    <AdminShell title="Settings" activeItem="settings">
      <SettingsProfile />
    </AdminShell>
  );
}
