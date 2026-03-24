'use client';

import { useEffect, useState } from 'react';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import styles from './dashboard-offline-banner.module.css';

const SPRING = { type: 'spring' as const, stiffness: 400, damping: 30 };

export function DashboardOfflineBanner() {
  const [isOnline, setIsOnline] = useState(true);
  const reducedMotion = useReducedMotion();

  useEffect(() => {
    setIsOnline(navigator.onLine);

    const onOnline = () => setIsOnline(true);
    const onOffline = () => setIsOnline(false);

    window.addEventListener('online', onOnline);
    window.addEventListener('offline', onOffline);

    return () => {
      window.removeEventListener('online', onOnline);
      window.removeEventListener('offline', onOffline);
    };
  }, []);

  return (
    <div className={styles.wrapper}>
      <AnimatePresence>
        {!isOnline ? (
          <motion.div
            key="offline-banner"
            className={styles.banner}
            role="alert"
            aria-live="polite"
            initial={reducedMotion ? false : { opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={reducedMotion ? { opacity: 0 } : { opacity: 0, y: -20 }}
            transition={reducedMotion ? { duration: 0 } : SPRING}
          >
            You are offline. Some actions may not work until the connection is restored.
          </motion.div>
        ) : null}
      </AnimatePresence>
    </div>
  );
}
