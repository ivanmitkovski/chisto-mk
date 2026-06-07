'use client';

import Link from 'next/link';
import type { ReactNode } from 'react';
import styles from './dropdown-menu.module.css';

type DropdownMenuItemBaseProps = {
  children: ReactNode;
  className?: string;
  onSelect?: () => void;
};

type DropdownMenuItemButtonProps = DropdownMenuItemBaseProps & {
  href?: undefined;
};

type DropdownMenuItemLinkProps = DropdownMenuItemBaseProps & {
  href: string;
};

export type DropdownMenuItemProps = DropdownMenuItemButtonProps | DropdownMenuItemLinkProps;

export function DropdownMenuItem({ children, className, onSelect, href }: DropdownMenuItemProps) {
  const itemClass = [styles.menuItem, className].filter(Boolean).join(' ');

  if (href) {
    return (
      <Link
        href={href}
        role="menuitem"
        className={itemClass}
        {...(onSelect ? { onClick: onSelect } : {})}
      >
        {children}
      </Link>
    );
  }

  return (
    <button type="button" role="menuitem" className={itemClass} {...(onSelect ? { onClick: onSelect } : {})}>
      {children}
    </button>
  );
}
