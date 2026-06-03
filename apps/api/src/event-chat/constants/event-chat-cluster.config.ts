import { Injectable } from '@nestjs/common';

/**
 * Set at bootstrap when the Socket.IO Redis adapter is active.
 * When true, Redis-ingested chat events must not call `gateway.emitToRoom` again
 * (the clustered adapter already delivered WebSocket payloads from the origin replica).
 */
@Injectable()
export class EventChatClusterConfig {
  private _socketIoClustered = false;

  get socketIoClustered(): boolean {
    return this._socketIoClustered;
  }

  setSocketIoClustered(value: boolean): void {
    this._socketIoClustered = value;
  }
}
