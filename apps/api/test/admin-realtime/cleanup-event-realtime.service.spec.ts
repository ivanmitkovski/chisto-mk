/// <reference types="jest" />

import { CleanupEventRealtimeService } from '../../src/admin-realtime/cleanup-event-realtime.service';

describe('CleanupEventRealtimeService', () => {
  it('emits cleanup_event_pending with eventId', (done) => {
    const svc = new CleanupEventRealtimeService();
    const sub = svc.getEvents().subscribe((ev) => {
      try {
        expect(ev.type).toBe('cleanup_event_pending');
        expect(ev.eventId).toBe('evt-pending-1');
        expect(ev.moderationStatus).toBe('PENDING');
        sub.unsubscribe();
        done();
      } catch (e) {
        sub.unsubscribe();
        done(e);
      }
    });
    svc.emitCleanupEventPending('evt-pending-1');
  });

  it('emits cleanup_event_updated with optional fields', (done) => {
    const svc = new CleanupEventRealtimeService();
    const sub = svc.getEvents().subscribe((ev) => {
      try {
        expect(ev.type).toBe('cleanup_event_updated');
        expect(ev.eventId).toBe('evt-2');
        expect(ev.moderationStatus).toBe('APPROVED');
        expect(ev.lifecycleStatus).toBe('COMPLETED');
        sub.unsubscribe();
        done();
      } catch (e) {
        sub.unsubscribe();
        done(e);
      }
    });
    svc.emitCleanupEventUpdated('evt-2', { moderationStatus: 'APPROVED', lifecycleStatus: 'COMPLETED' });
  });
});
