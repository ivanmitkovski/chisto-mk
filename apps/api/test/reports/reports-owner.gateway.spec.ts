import { Namespace, Socket } from 'socket.io';
import { ReportsOwnerGateway } from '../../src/reports/owner-events/reports-owner.gateway';
import { authenticateSocketUser } from '../../src/common/ws/authenticate-socket-user';
import { ReportsOwnerEventsService } from '../../src/reports/services/reports-owner-events.service';
import { Subject } from 'rxjs';

jest.mock('../../src/common/ws/authenticate-socket-user', () => ({
  authenticateSocketUser: jest.fn(),
}));

describe('ReportsOwnerGateway', () => {
  const authenticateSocketUserMock = authenticateSocketUser as jest.MockedFunction<
    typeof authenticateSocketUser
  >;

  let gateway: ReportsOwnerGateway;
  let events$: Subject<unknown>;

  beforeEach(() => {
    events$ = new Subject();
    authenticateSocketUserMock.mockReset();
    gateway = new ReportsOwnerGateway(
      { get: jest.fn() } as never,
      {} as never,
      {
        getEventsForOwner: jest.fn().mockReturnValue(events$.asObservable()),
      } as unknown as ReportsOwnerEventsService,
    );
    (gateway as unknown as { server: Namespace }).server = {
      sockets: new Map<string, Socket>(),
    } as unknown as Namespace;
  });

  it('registers auth middleware in afterInit', () => {
    const useFn = jest.fn();
    const server = { use: useFn } as unknown as Namespace;
    gateway.afterInit(server);
    expect(useFn).toHaveBeenCalledTimes(1);
    expect(typeof useFn.mock.calls[0]?.[0]).toBe('function');
  });

  it('middleware rejects unauthenticated sockets', async () => {
    authenticateSocketUserMock.mockRejectedValue(new Error('no token'));
    const useFn = jest.fn();
    const server = { use: useFn } as unknown as Namespace;
    gateway.afterInit(server);
    const middleware = useFn.mock.calls[0]![0] as (
      socket: Socket,
      next: (err?: Error) => void,
    ) => Promise<void>;
    const next = jest.fn();
    await middleware({ data: {} } as Socket, next);
    expect(next).toHaveBeenCalledWith(expect.objectContaining({ message: 'AUTH_FAILED' }));
  });

  it('handleConnection emits reports_owner.ready for authenticated socket', () => {
    const emitted: Array<{ event: string; payload: unknown }> = [];
    const client = {
      id: 'sock-1',
      data: { userId: 'user-1' },
      emit: jest.fn((event: string, payload: unknown) => {
        emitted.push({ event, payload });
      }),
      disconnect: jest.fn(),
    } as unknown as Socket;

    gateway.handleConnection(client);

    expect(emitted).toContainEqual({
      event: 'reports_owner.ready',
      payload: { userId: 'user-1' },
    });
  });

  it('handleConnection disconnects previous socket for same user on reconnect', () => {
    const previousDisconnect = jest.fn();
    const previousSocket = {
      id: 'sock-old',
      disconnect: previousDisconnect,
    } as unknown as Socket;
    (gateway as unknown as { server: Namespace }).server = {
      sockets: new Map<string, Socket>([['sock-old', previousSocket]]),
    } as unknown as Namespace;

    gateway.handleConnection({
      id: 'sock-old',
      data: { userId: 'user-1' },
      emit: jest.fn(),
      disconnect: jest.fn(),
    } as unknown as Socket);

    const client = {
      id: 'sock-new',
      data: { userId: 'user-1' },
      emit: jest.fn(),
      disconnect: jest.fn(),
    } as unknown as Socket;

    gateway.handleConnection(client);

    expect(previousDisconnect).toHaveBeenCalledWith(true);
  });
});
