'use client';

import { type ReactNode } from 'react';
import { motion, useReducedMotion } from 'framer-motion';

const SPRING = { type: 'spring' as const, stiffness: 400, damping: 30 };

type DashboardSectionWrapperProps = {
  children: ReactNode;
  delay?: number;
  className?: string;
};

export function DashboardSectionWrapper({
  children,
  delay = 0,
  className,
}: DashboardSectionWrapperProps) {
  const reducedMotion = useReducedMotion();

  return (
    <motion.div
      initial={reducedMotion ? false : { opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={
        reducedMotion
          ? { duration: 0 }
          : { ...SPRING, delay }
      }
      className={className}
    >
      {children}
    </motion.div>
  );
}
