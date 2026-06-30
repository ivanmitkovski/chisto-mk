/**
 * @vitest-environment jsdom
 */
import { describe, expect, it, vi, afterEach } from 'vitest';
import { cleanup, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { BroadcastCampaignCard } from './broadcast-campaign-card';
import { renderWithProviders } from '@/test/render-with-providers';
import type { BroadcastCampaign } from '../types';

vi.mock('@/lib/auth/rbac/use-permissions', () => ({
  usePermissions: () => ({
    can: (permission: string) => permission === 'notifications:broadcast',
    canAny: () => true,
    canAll: () => true,
  }),
}));

const draftCampaign: BroadcastCampaign = {
  id: 'campaign-1',
  title: 'Weekly update',
  body: 'Hello everyone',
  audience: 'all',
  status: 'draft',
};

const sentCampaign: BroadcastCampaign = {
  ...draftCampaign,
  id: 'campaign-2',
  status: 'sent',
  sentAt: '2026-06-01T10:00:00.000Z',
  sentCount: 42,
};

describe('BroadcastCampaignCard', () => {
  afterEach(() => {
    cleanup();
  });

  it('shows delete control for deletable campaigns', () => {
    renderWithProviders(
      <BroadcastCampaignCard
        campaign={draftCampaign}
        busy={false}
        isEditing={false}
        onEdit={vi.fn()}
        onSend={vi.fn()}
        onCancel={vi.fn()}
        onDelete={vi.fn()}
      />,
    );

    expect(screen.getByRole('button', { name: 'Delete Weekly update' })).toBeInTheDocument();
  });

  it('hides delete control for sent campaigns', () => {
    renderWithProviders(
      <BroadcastCampaignCard
        campaign={sentCampaign}
        busy={false}
        isEditing={false}
        onEdit={vi.fn()}
        onSend={vi.fn()}
        onCancel={vi.fn()}
        onDelete={vi.fn()}
      />,
    );

    expect(screen.queryByRole('button', { name: 'Delete Weekly update' })).not.toBeInTheDocument();
  });

  it('calls onDelete when trash icon is clicked', async () => {
    const user = userEvent.setup();
    const onDelete = vi.fn();

    renderWithProviders(
      <BroadcastCampaignCard
        campaign={draftCampaign}
        busy={false}
        isEditing={false}
        onEdit={vi.fn()}
        onSend={vi.fn()}
        onCancel={vi.fn()}
        onDelete={onDelete}
      />,
    );

    await user.click(screen.getByRole('button', { name: 'Delete Weekly update' }));
    expect(onDelete).toHaveBeenCalledWith(draftCampaign);
  });
});
