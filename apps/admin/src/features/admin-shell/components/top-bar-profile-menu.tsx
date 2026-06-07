'use client';

import { RefObject } from 'react';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import { Button, Icon } from '@/components/ui';
import { signOutAndRedirectToLogin } from '@/features/auth/lib/admin-auth';
import { profileMenuActions } from '../data/top-bar-mocks';
import barStyles from './top-bar.module.css';
import styles from './top-bar-profile-menu.module.css';

type TopBarProfileMenuProps = {
  isOpen: boolean;
  profileButtonRef: RefObject<HTMLButtonElement | null>;
  profileMenuRef: RefObject<HTMLDivElement | null>;
  onToggle: () => void;
  onClose: () => void;
};

export function TopBarProfileMenu({
  isOpen,
  profileButtonRef,
  profileMenuRef,
  onToggle,
  onClose,
}: TopBarProfileMenuProps) {
  const router = useRouter();
  const tCommon = useTranslations('common');
  const tProfileMenu = useTranslations('nav.profileMenu');
  const reduceMotion = useReducedMotion();

  function handleProfileAction(action: (typeof profileMenuActions)[number]['action']) {
    if (action === 'go-to-settings') {
      onClose();
      router.push('/dashboard/settings');
      return;
    }

    if (action === 'open-preferences') {
      onClose();
      router.push('/dashboard/settings?section=preferences');
      return;
    }

    if (action === 'sign-out') {
      onClose();
      void signOutAndRedirectToLogin();
    }
  }

  return (
    <motion.span className={barStyles.profileWrap} {...(!reduceMotion ? { whileHover: { y: -1 } } : {})}>
      <Button
        ref={profileButtonRef}
        variant="icon"
        aria-label={tCommon('profile')}
        aria-expanded={isOpen}
        aria-haspopup="menu"
        className={`${barStyles.profileButton} ${isOpen ? barStyles.iconButtonOpen : ''}`}
        onClick={onToggle}
      >
        <Icon name="user" size={16} />
      </Button>
      <AnimatePresence>
        {isOpen ? (
          <motion.section
            ref={profileMenuRef}
            className={styles.dropdownPanel}
            role="menu"
            aria-label={tCommon('profileActions')}
            initial={reduceMotion ? false : { opacity: 0, y: -6, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={reduceMotion ? { opacity: 0 } : { opacity: 0, y: -6, scale: 0.98 }}
            transition={{ duration: reduceMotion ? 0 : 0.16 }}
          >
            <ul className={styles.profileActions}>
              {profileMenuActions.map((item) => (
                <li key={item.id}>
                  <button
                    type="button"
                    role="menuitem"
                    className={styles.profileActionButton}
                    onClick={() => handleProfileAction(item.action)}
                  >
                    <Icon name={item.icon} size={15} />
                    {tProfileMenu(item.labelKey)}
                  </button>
                </li>
              ))}
            </ul>
          </motion.section>
        ) : null}
      </AnimatePresence>
    </motion.span>
  );
}
