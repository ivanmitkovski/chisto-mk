import { describe, expect, it, vi, afterEach, beforeEach } from 'vitest';
import { cleanup, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { BroadcastAudienceUserPicker } from './broadcast-audience-user-picker';
import { renderWithProviders } from '@/test/render-with-providers';

vi.mock('@/lib/api', () => ({
  fetchUsers: vi.fn(),
}));

import { fetchUsers } from '@/lib/api';

const searchUsers = [
  {
    id: 'user-1',
    firstName: 'Ada',
    lastName: 'Lovelace',
    email: 'ada@example.com',
    phoneNumber: '',
  },
  {
    id: 'user-2',
    firstName: 'Grace',
    lastName: 'Hopper',
    email: 'grace@example.com',
    phoneNumber: '',
  },
];

describe('BroadcastAudienceUserPicker', () => {
  beforeEach(() => {
    vi.mocked(fetchUsers).mockResolvedValue({
      data: searchUsers,
      meta: { total: 2, page: 1, limit: 20 },
    });
    vi.useFakeTimers({ shouldAdvanceTime: true });
  });

  afterEach(() => {
    cleanup();
    vi.useRealTimers();
  });

  it('shows helper text without opening an empty results panel on focus', async () => {
    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime });

    renderWithProviders(
      <BroadcastAudienceUserPicker selectedUsers={[]} onChange={vi.fn()} />,
    );

    const input = screen.getByRole('combobox');
    await user.click(input);

    expect(screen.getByText('Type a name or email to find users.')).toBeInTheDocument();
    expect(screen.queryByRole('listbox')).not.toBeInTheDocument();
  });

  it('adds and removes selected users', async () => {
    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime });
    const onChange = vi.fn();

    renderWithProviders(
      <BroadcastAudienceUserPicker selectedUsers={[]} onChange={onChange} />,
    );

    const input = screen.getByRole('combobox');
    await user.click(input);
    await user.type(input, 'Ada');
    await vi.advanceTimersByTimeAsync(350);

    await waitFor(() => {
      expect(screen.getByRole('option', { name: /Ada Lovelace/ })).toBeInTheDocument();
    });

    await user.click(screen.getByRole('option', { name: /Ada Lovelace/ }));
    expect(onChange).toHaveBeenCalledWith([
      { id: 'user-1', label: 'Ada Lovelace · ada@example.com' },
    ]);
  });

  it('marks the keyboard-highlighted option with aria-selected', async () => {
    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime });

    renderWithProviders(
      <BroadcastAudienceUserPicker selectedUsers={[]} onChange={vi.fn()} />,
    );

    const input = screen.getByRole('combobox');
    await user.click(input);
    await user.type(input, 'a');
    await vi.advanceTimersByTimeAsync(350);

    await waitFor(() => {
      const options = screen.getAllByRole('option');
      expect(options).toHaveLength(2);
      expect(options[0]).toHaveAttribute('aria-selected', 'true');
      expect(options[1]).toHaveAttribute('aria-selected', 'false');
    });

    await user.keyboard('{ArrowDown}');

    await waitFor(() => {
      const options = screen.getAllByRole('option');
      expect(options[0]).toHaveAttribute('aria-selected', 'false');
      expect(options[1]).toHaveAttribute('aria-selected', 'true');
    });
  });

  it('does not add duplicate users', async () => {
    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime });
    const onChange = vi.fn();

    renderWithProviders(
      <BroadcastAudienceUserPicker
        selectedUsers={[{ id: 'user-1', label: 'Ada Lovelace · ada@example.com' }]}
        onChange={onChange}
      />,
    );

    expect(screen.getByText('Ada Lovelace · ada@example.com')).toBeInTheDocument();

    const input = screen.getByRole('combobox');
    await user.click(input);
    await user.type(input, 'Ada');
    await vi.advanceTimersByTimeAsync(350);

    await waitFor(() => {
      expect(fetchUsers).toHaveBeenCalled();
    });

    expect(screen.queryByRole('option', { name: /Ada Lovelace/ })).not.toBeInTheDocument();
  });
});
