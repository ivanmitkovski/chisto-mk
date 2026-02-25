'use client';

import { useState } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { Button, Card, Icon, Input } from '@/components/ui';
import { useSettingsForm } from '../hooks/use-settings-form';
import styles from './settings-profile.module.css';

export function SettingsProfile() {
  const [activeTab, setActiveTab] = useState<'profile' | 'preferences'>('profile');
  const { values, errors, successMessage, updateField, handleSubmit } = useSettingsForm();

  return (
    <motion.div
      initial={{ opacity: 0, y: 14 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.28, ease: 'easeOut' }}
    >
      <Card className={styles.card}>
        <h2 className={styles.title}>Settings</h2>
        <div className={styles.tabs} role="tablist" aria-label="Settings tabs">
          <button
            type="button"
            role="tab"
            aria-selected={activeTab === 'profile'}
            className={`${styles.tab} ${activeTab === 'profile' ? styles.tabActive : ''}`}
            onClick={() => setActiveTab('profile')}
          >
            Edit Profile
          </button>
          <button
            type="button"
            role="tab"
            aria-selected={activeTab === 'preferences'}
            className={`${styles.tab} ${activeTab === 'preferences' ? styles.tabActive : ''}`}
            onClick={() => setActiveTab('preferences')}
          >
            Preferences
          </button>
        </div>

        <AnimatePresence mode="wait">
          {activeTab === 'profile' ? (
            <motion.div
              key="profile-tab"
              className={styles.grid}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -8 }}
              transition={{ duration: 0.2 }}
            >
              <div className={styles.avatarBlock}>
                <div className={styles.avatar}>
                  <Icon name="user" size={34} className={styles.avatarIcon} />
                </div>
                <Button type="button" variant="outline" size="sm">
                  Upload photo
                </Button>
              </div>

              <form className={styles.form} onSubmit={handleSubmit}>
                <Input
                  id="settings-identity"
                  label="Change email or phone"
                  placeholder="Enter email or phone"
                  value={values.identity}
                  onChange={(event) => updateField('identity', event.target.value)}
                  errorText={errors.identity}
                />
                <Input
                  id="settings-password"
                  label="Password"
                  type="password"
                  placeholder="Enter password"
                  value={values.password}
                  onChange={(event) => updateField('password', event.target.value)}
                  errorText={errors.password}
                />
                <div className={styles.actions}>
                  <Button type="submit">
                    <Icon name="check" size={14} />
                    Save
                  </Button>
                </div>
              </form>

              {successMessage ? (
                <p className={styles.message} role="status">
                  {successMessage}
                </p>
              ) : null}
            </motion.div>
          ) : (
            <motion.p
              key="preferences-tab"
              className={styles.placeholder}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -8 }}
              transition={{ duration: 0.2 }}
            >
              Preferences controls will be introduced in the next admin iteration.
            </motion.p>
          )}
        </AnimatePresence>
      </Card>
    </motion.div>
  );
}
