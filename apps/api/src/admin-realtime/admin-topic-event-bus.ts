import { Subject } from 'rxjs';
import type { Observable } from 'rxjs';

/**
 * Small RxJS fan-out primitive for admin realtime topics (replaces copy-pasted `Subject` wiring).
 */
export class AdminTopicEventBus<T> {
  private readonly events$ = new Subject<T>();

  getEvents(): Observable<T> {
    return this.events$.asObservable();
  }

  emit(event: T): void {
    this.events$.next(event);
  }
}
