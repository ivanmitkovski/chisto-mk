'use client';

import { FormEvent } from 'react';
import { useRouter } from 'next/navigation';
import { motion } from 'framer-motion';
import { Brand, Button, Input, Snack } from '@/components/ui';
import { useLoginForm } from '../hooks/use-login-form';
import styles from './login-screen.module.css';

export function LoginScreen() {
  const router = useRouter();
  const { values, errors, snack, updateField, handleSubmit, clearSnack } = useLoginForm();
  const currentYear = new Date().getFullYear();

  function onSubmit(event: FormEvent<HTMLFormElement>) {
    const isValid = handleSubmit(event);

    if (isValid) {
      window.setTimeout(() => {
        router.push('/dashboard');
      }, 480);
    }
  }

  return (
    <main className={styles.root}>
      <motion.section
        className={styles.left}
        initial={{ opacity: 0, x: -22 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ duration: 0.34, ease: 'easeOut' }}
      >
        <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.08 }}>
          <Brand priority />
        </motion.div>
        <h1 className={styles.title}>Sign in</h1>

        <motion.form
          className={styles.form}
          onSubmit={onSubmit}
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.12, duration: 0.24 }}
        >
          <Input
            id="login-identity"
            label="Email or phone"
            placeholder="+389 70 123 456"
            value={values.identity}
            onChange={(event) => updateField('identity', event.target.value)}
            errorText={errors.identity}
          />
          <Input
            id="login-password"
            label="Password"
            type="password"
            placeholder="************"
            value={values.password}
            onChange={(event) => updateField('password', event.target.value)}
            errorText={errors.password}
          />
          <p className={styles.hint}>Demo: admin@chisto.mk / chisto1234</p>
          <Button className={styles.button} type="submit">
            Login
          </Button>
        </motion.form>

        <p className={styles.footer}>Copyright {currentYear} Chisto.mk. All rights reserved.</p>
      </motion.section>

      <motion.section
        className={styles.right}
        initial={{ opacity: 0, scale: 1.03 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.45, ease: 'easeOut' }}
      />

      <Snack snack={snack} onClose={clearSnack} />
    </main>
  );
}
