import { describe, expect, it } from 'vitest';
import {
  AM_MATCH_CONFIG,
  amBestBuddy,
  amBuildBlockSet,
  amCreateCooldownIndex,
  amHardFilter,
  amScoreCandidate,
  amSmoothedRating,
  amSmoothedSuccess,
  amTeachLearnCopy,
} from './amMatchScore.js';

const NOW = 1_800_000_000_000;
let seq = 0;
export function amMakeUser(over = {}) {
  seq += 1;
  return {
    id: over.id ?? `u${seq}`,
    name: over.name ?? `User${seq}`,
    mode: 'buddy',
    sameSchoolOnly: false,
    joinedAt: NOW - 5_000,
    lastSeen: NOW - 1_000,
    status: 'waiting',
    weak: ['Math'],
    strong: ['English'],
    languages: ['English'],
    school: 'UP Diliman',
    ratingAvg: 0,
    ratingCount: 0,
    successCount: 0,
    sessionsCount: 0,
    suspendedUntil: 0,
    ...over,
  };
}
const ctx = (over = {}) => ({ now: NOW, blockSet: new Set(), cooldowns: amCreateCooldownIndex([]), ...over });

describe('scoring', () => {
  it('two-way beats one-way', () => {
    const seed = amMakeUser({ weak: ['Math'], strong: ['English'], joinedAt: NOW - 40_000 });
    const twoWay = amMakeUser({ weak: ['English'], strong: ['Math'] });
    const oneWay = amMakeUser({ weak: ['Science'], strong: ['Math'] });
    const best = amBestBuddy(seed, [oneWay, twoWay], ctx());
    expect(best.user.id).toBe(twoWay.id);
    expect(best.result.twoWay).toBe(true);
  });

  it('one-way matches are only allowed after 30s of waiting', () => {
    const fresh = amMakeUser({ weak: ['Math'], strong: ['English'], joinedAt: NOW - 5_000 });
    const oneWay = amMakeUser({ weak: ['Science'], strong: ['Math'], joinedAt: NOW - 5_000 });
    expect(amScoreCandidate(fresh, oneWay, ctx())).toBeNull();
    const waited = { ...fresh, joinedAt: NOW - AM_MATCH_CONFIG.relaxAfterMs - 1 };
    expect(amScoreCandidate(waited, oneWay, ctx())).not.toBeNull();
  });

  it('a shared language breaks ties', () => {
    const seed = amMakeUser({ languages: ['Filipino'] });
    const a = amMakeUser({ weak: ['English'], strong: ['Math'], languages: ['Japanese'], joinedAt: NOW - 5_000 });
    const b = amMakeUser({ weak: ['English'], strong: ['Math'], languages: ['Filipino'], joinedAt: NOW - 5_000 });
    expect(amBestBuddy(seed, [a, b], ctx()).user.id).toBe(b.id);
  });

  it('language is a soft boost, not a filter', () => {
    const seed = amMakeUser({ languages: ['Filipino'] });
    const other = amMakeUser({ weak: ['English'], strong: ['Math'], languages: ['Korean'] });
    expect(amBestBuddy(seed, [other], ctx())).not.toBeNull();
  });

  it('smooths ratings so newcomers are not ranked last', () => {
    const newbie = amMakeUser();
    const poor = amMakeUser({ ratingAvg: 2, ratingCount: 20 });
    const great = amMakeUser({ ratingAvg: 4.9, ratingCount: 20 });
    expect(amSmoothedRating(newbie)).toBeGreaterThan(amSmoothedRating(poor));
    expect(amSmoothedRating(great)).toBeGreaterThan(amSmoothedRating(newbie));
    expect(amSmoothedSuccess(newbie)).toBeCloseTo(AM_MATCH_CONFIG.successPrior);
  });

  it('weights sum to 1', () => {
    const sum = Object.values(AM_MATCH_CONFIG.weights).reduce((a, b) => a + b, 0);
    expect(sum).toBeCloseTo(1);
  });
});

describe('hard filters', () => {
  const a = amMakeUser({ id: 'a', weak: ['Math'], strong: ['English'] });
  const b = amMakeUser({ id: 'b', weak: ['English'], strong: ['Math'] });

  it('passes a compatible pair', () => {
    expect(amHardFilter(a, b, ctx()).ok).toBe(true);
  });
  it('excludes blocked pairs in either direction', () => {
    const blockSet = amBuildBlockSet([{ blocker_id: 'b', blocked_id: 'a' }]);
    expect(amHardFilter(a, b, ctx({ blockSet })).reason).toBe('blocked');
  });
  it('excludes suspended users', () => {
    expect(amHardFilter(a, { ...b, suspendedUntil: NOW + 60_000 }, ctx()).reason).toBe('suspended');
    expect(amHardFilter(a, { ...b, suspendedUntil: NOW - 60_000 }, ctx()).ok).toBe(true);
  });
  it('excludes stale and different-mode users', () => {
    expect(amHardFilter(a, { ...b, lastSeen: NOW - 31_000 }, ctx()).reason).toBe('stale');
    expect(amHardFilter(a, { ...b, mode: 'peers' }, ctx()).reason).toBe('mode');
  });
  it('respects same-school-only when either side enabled it', () => {
    const other = { ...b, school: 'Ateneo' };
    expect(amHardFilter(a, other, ctx()).ok).toBe(true);
    expect(amHardFilter({ ...a, sameSchoolOnly: true }, other, ctx()).reason).toBe('school');
    expect(amHardFilter(a, { ...other, sameSchoolOnly: true }, ctx()).reason).toBe('school');
    expect(amHardFilter({ ...a, sameSchoolOnly: true }, { ...b, school: 'up diliman' }, ctx()).ok).toBe(true);
  });
  it('requires subject overlap', () => {
    const c = amMakeUser({ weak: ['History'], strong: ['Science'] });
    expect(amHardFilter(a, c, ctx()).reason).toBe('no-overlap');
  });
});

describe('cooldowns', () => {
  const session = (ids, minsAgo, status = 'accepted', accepted = true) => ({
    id: `p${Math.random()}`,
    createdAt: NOW - minsAgo * 60_000,
    status,
    mode: 'buddy',
    members: ids.map((userId) => ({ userId, accepted })),
  });

  it('blocks the same pair for 24h after a session', () => {
    const cooldowns = amCreateCooldownIndex([session(['a', 'b'], 60)]);
    expect(cooldowns.inPairCooldown('a', 'b', NOW)).toBe(true);
    const old = amCreateCooldownIndex([session(['a', 'b'], 25 * 60)]);
    expect(old.inPairCooldown('a', 'b', NOW)).toBe(false);
  });

  it('lifts after both users had 5 other matches', () => {
    const hist = [session(['a', 'b'], 120)];
    for (let i = 0; i < 5; i++) hist.push(session(['a', `x${i}`], 100 - i), session(['b', `y${i}`], 100 - i));
    expect(amCreateCooldownIndex(hist).inPairCooldown('a', 'b', NOW)).toBe(false);
    const partial = hist.filter((p) => !p.members.some((m) => m.userId.startsWith('y')));
    expect(amCreateCooldownIndex(partial).inPairCooldown('a', 'b', NOW)).toBe(true);
  });

  it('declines and timeouts put the pair in cooldown', () => {
    const p = { ...session(['a', 'b'], 1, 'declined'), members: [{ userId: 'a', accepted: true }, { userId: 'b', accepted: false }] };
    expect(amCreateCooldownIndex([p]).inPairCooldown('a', 'b', NOW)).toBe(true);
    const expired = { ...p, status: 'expired', members: [{ userId: 'a', accepted: true }, { userId: 'b', accepted: null }] };
    expect(amCreateCooldownIndex([expired]).inPairCooldown('a', 'b', NOW)).toBe(true);
  });

  it('peers: a decliner only cools down with others, not acceptors with each other', () => {
    const p = {
      ...session(['a', 'b', 'c'], 1, 'declined'),
      mode: 'peers',
      members: [{ userId: 'a', accepted: true }, { userId: 'b', accepted: true }, { userId: 'c', accepted: false }],
    };
    const cd = amCreateCooldownIndex([p]);
    expect(cd.inPairCooldown('a', 'b', NOW, 'peers')).toBe(false);
    expect(cd.inPairCooldown('a', 'c', NOW, 'peers')).toBe(true);
  });

  it('excluded from best buddy when in cooldown', () => {
    const a = amMakeUser({ id: 'a' });
    const b = amMakeUser({ id: 'b', weak: ['English'], strong: ['Math'] });
    const cooldowns = amCreateCooldownIndex([session(['a', 'b'], 5)]);
    expect(amBestBuddy(a, [b], ctx({ cooldowns }))).toBeNull();
  });

  it('group rule: >= half of the group shared a session', () => {
    const cd = amCreateCooldownIndex([{ ...session(['a', 'b'], 30), mode: 'peers' }]);
    expect(cd.groupInCooldown(['a', 'b', 'c'], NOW)).toBe(true); // 2 of 3
    expect(cd.groupInCooldown(['a', 'b', 'c', 'd'], NOW)).toBe(true); // 2 of 4
    expect(cd.groupInCooldown(['a', 'b', 'c', 'd', 'e'], NOW)).toBe(false); // 2 of 5
    expect(cd.inPairCooldown('a', 'b', NOW, 'peers')).toBe(false);
  });
});

describe('teach/learn copy', () => {
  it('builds friendly sentences', () => {
    const me = { weak: ['English'], strong: ['Math'] };
    const copy = amTeachLearnCopy(me, [
      { name: 'Ana', weak: ['Math'], strong: ['English'] },
      { name: 'Ben', weak: ['Math'], strong: ['Science'] },
    ]);
    expect(copy.teach[0].text).toBe("You'll help Ana & Ben with Math");
    expect(copy.learn[0].text).toBe('Ana will help you with English');
    expect(copy.headline).toMatch(/swap/);
  });
});
