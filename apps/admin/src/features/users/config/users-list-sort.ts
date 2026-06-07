export const USERS_SORT_KEYS = ['lastActiveAt', 'name', 'email', 'pointsBalance', 'createdAt'] as const;
export type UsersSortKey = (typeof USERS_SORT_KEYS)[number];
export type UsersSortDir = 'asc' | 'desc';

export function isUsersSortKey(value: string | null | undefined): value is UsersSortKey {
  return USERS_SORT_KEYS.includes(value as UsersSortKey);
}

export const USERS_SORT_OPTIONS: { value: UsersSortKey; labelKey: string }[] = [
  { value: 'lastActiveAt', labelKey: 'table.lastActive' },
  { value: 'name', labelKey: 'table.name' },
  { value: 'email', labelKey: 'table.email' },
  { value: 'pointsBalance', labelKey: 'table.points' },
  { value: 'createdAt', labelKey: 'table.created' },
];
