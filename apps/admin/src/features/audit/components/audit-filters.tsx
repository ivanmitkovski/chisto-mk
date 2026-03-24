'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useCallback, useState } from 'react';
import { Button, Input } from '@/components/ui';
import styles from './audit-filters.module.css';

export function AuditFilters() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [action, setAction] = useState(searchParams.get('action') ?? '');
  const [resourceType, setResourceType] = useState(searchParams.get('resourceType') ?? '');
  const [actorId, setActorId] = useState(searchParams.get('actorId') ?? '');
  const [from, setFrom] = useState(searchParams.get('from') ?? '');
  const [to, setTo] = useState(searchParams.get('to') ?? '');

  const apply = useCallback(() => {
    const params = new URLSearchParams();
    if (action) params.set('action', action);
    if (resourceType) params.set('resourceType', resourceType);
    if (actorId) params.set('actorId', actorId);
    if (from) params.set('from', from);
    if (to) params.set('to', to);
    router.push(`/dashboard/audit?${params.toString()}`);
  }, [router, action, resourceType, actorId, from, to]);

  const clear = useCallback(() => {
    setAction('');
    setResourceType('');
    setActorId('');
    setFrom('');
    setTo('');
    router.push('/dashboard/audit');
  }, [router]);

  return (
    <div className={styles.wrap}>
      <div className={styles.row}>
        <Input
          label="Action"
          value={action}
          onChange={(e) => setAction(e.target.value)}
          placeholder="e.g. USER_UPDATED"
        />
        <Input
          label="Resource type"
          value={resourceType}
          onChange={(e) => setResourceType(e.target.value)}
          placeholder="e.g. User, Report"
        />
        <Input
          label="Actor ID"
          value={actorId}
          onChange={(e) => setActorId(e.target.value)}
          placeholder="User ID"
        />
        <Input
          label="From (ISO date)"
          type="date"
          value={from}
          onChange={(e) => setFrom(e.target.value)}
        />
        <Input
          label="To (ISO date)"
          type="date"
          value={to}
          onChange={(e) => setTo(e.target.value)}
        />
      </div>
      <div className={styles.actions}>
        <Button type="button" onClick={apply}>
          Apply filters
        </Button>
        <Button type="button" variant="outline" onClick={clear}>
          Clear
        </Button>
      </div>
    </div>
  );
}
