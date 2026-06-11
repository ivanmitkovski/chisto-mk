/// <reference types="jest" />
import { UserStatus } from '../../src/prisma-client';
import {
  participantDisplayName,
  projectLeaderboardIdentity,
  projectPublicReporter,
  resolveActorIdentity,
} from '../../src/common/projections/public-identity.projection';

describe('resolveActorIdentity', () => {
  it('returns deleted when user row is missing but actor id is known', () => {
    expect(resolveActorIdentity(null, { actorUserId: 'u1' })).toEqual({
      displayName: null,
      isDeleted: true,
      isAnonymous: false,
    });
  });

  it('returns anonymous when user row is missing and no actor id', () => {
    expect(resolveActorIdentity(null)).toEqual({
      displayName: 'Anonymous',
      isDeleted: false,
      isAnonymous: true,
    });
  });

  it('returns deleted when user status is DELETED', () => {
    expect(
      resolveActorIdentity(
        { firstName: 'Deleted', lastName: 'User', status: UserStatus.DELETED },
        { actorUserId: 'u1' },
      ),
    ).toEqual({
      displayName: null,
      isDeleted: true,
      isAnonymous: false,
    });
  });

  it('returns anonymous for empty names on active users', () => {
    expect(
      resolveActorIdentity(
        { firstName: '', lastName: '', status: UserStatus.ACTIVE },
        { actorUserId: 'u1' },
      ),
    ).toEqual({
      displayName: 'Anonymous',
      isDeleted: false,
      isAnonymous: true,
    });
  });

  it('returns full name for active users', () => {
    expect(
      resolveActorIdentity(
        { firstName: 'Melanija', lastName: 'Stojcheva', status: UserStatus.ACTIVE },
        { actorUserId: 'u1' },
      ),
    ).toEqual({
      displayName: 'Melanija Stojcheva',
      isDeleted: false,
      isAnonymous: false,
    });
  });
});

describe('projectPublicReporter', () => {
  it('marks soft-deleted reporters as deleted without surfacing stored name', () => {
    const view = projectPublicReporter(
      'u1',
      { firstName: 'Deleted', lastName: 'User', status: UserStatus.DELETED },
      undefined,
      false,
    );
    expect(view).toEqual({
      displayLabel: null,
      isSelf: false,
      isDeleted: true,
      isAnonymous: false,
    });
  });
});

describe('projectLeaderboardIdentity', () => {
  const activeUser = {
    id: 'user-other',
    firstName: 'Filip',
    lastName: 'Gjorgiev',
    showOnLeaderboard: true,
    status: UserStatus.ACTIVE,
  };

  it('returns full name for opted-in users visible to other viewers', () => {
    expect(projectLeaderboardIdentity(activeUser, 'viewer-1')).toEqual({
      displayLabel: 'Filip Gjorgiev',
      userId: 'user-other',
    });
  });

  it('returns Anonymous without userId when user opted out', () => {
    expect(
      projectLeaderboardIdentity(
        { ...activeUser, showOnLeaderboard: false },
        'viewer-1',
      ),
    ).toEqual({ displayLabel: 'Anonymous' });
  });

  it('returns full name for self even when opted out', () => {
    expect(
      projectLeaderboardIdentity(
        { ...activeUser, showOnLeaderboard: false },
        'user-other',
      ),
    ).toEqual({ displayLabel: 'Filip Gjorgiev' });
  });
});

describe('participantDisplayName', () => {
  it('flags deleted participants with empty display name', () => {
    expect(
      participantDisplayName(null, { actorUserId: 'u1', fallback: 'Volunteer' }),
    ).toEqual({ displayName: '', isDeleted: true });
  });
});
