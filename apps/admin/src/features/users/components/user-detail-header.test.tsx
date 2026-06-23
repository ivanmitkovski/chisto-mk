import type { ComponentProps } from 'react';
import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import { NextIntlClientProvider } from 'next-intl';
import { UserDetailHeader } from './user-detail-header';

const messages = {
  users: {
    deletedUser: 'Deleted user',
    filters: {
      roleUser: 'User',
      active: 'Active',
    },
    detail: {
      header: {
        lastActive: 'Last active: {value}',
        copyId: 'Copy ID',
      },
    },
  },
};

function renderHeader(props: Partial<ComponentProps<typeof UserDetailHeader>> = {}) {
  return render(
    <NextIntlClientProvider locale="en" messages={messages}>
      <UserDetailHeader
        userId="user-1"
        firstName="Ada"
        lastName="Lovelace"
        email="ada@example.com"
        role="USER"
        status="ACTIVE"
        lastActiveAt={null}
        {...props}
      />
    </NextIntlClientProvider>,
  );
}

describe('UserDetailHeader', () => {
  it('renders initials when avatarUrl is missing', () => {
    renderHeader();
    expect(screen.getByText('AL')).toBeInTheDocument();
  });

  it('renders avatar image when avatarUrl is provided', () => {
    const { container } = renderHeader({ avatarUrl: 'https://cdn.example/avatar.jpg' });
    const image = container.querySelector('img');
    expect(image).not.toBeNull();
    expect(image?.getAttribute('src')).toContain(encodeURIComponent('https://cdn.example/avatar.jpg'));
  });
});
