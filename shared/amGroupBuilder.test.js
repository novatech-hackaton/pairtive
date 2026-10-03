import { describe, expect, it } from 'vitest';
import { amCreateCooldownIndex, amTeachLearn } from './amMatchScore.js';
import { amAllWeakCovered, amBuildGroup, amPlanMatches } from './amGroupBuilder.js';

const NOW = 1_800_000_000_000;
const user = (id, weak, strong, over = {}) => ({
  id,
  name: id,
  mode: 'peers',
  sameSchoolOnly: false,
  joinedAt: NOW - 10_000,
  lastSeen: NOW - 1_000,
  status: 'waiting',
  weak,
  strong,
  languages: ['English'],
  school: 'UPD',
  ratingAvg: 0,
  ratingCount: 0,
  successCount: 0,
  sessionsCount: 0,
  suspendedUntil: 0,
  ...over,
});
const ctx = (over = {}) => ({ now: NOW, blockSet: new Set(), cooldowns: amCreateCooldownIndex([]), ...over });

describe('amBuildGroup', () => {
  it('builds a 3-person rotation where everyone teaches and learns', () => {
    const a = user('a', ['Math'], ['English'], { joinedAt: NOW - 20_000 });
    const b = user('b', ['English'], ['Science']);
    const c = user('c', ['Science'], ['Math']);
    const group = amBuildGroup(a, [b, c], ctx());
    expect(group.map((m) => m.id).sort()).toEqual(['a', 'b', 'c']);
    expect(amAllWeakCovered(group)).toBe(true);
    for (const m of group) {
      const tl = amTeachLearn(m, group.filter((o) => o.id !== m.id));
      expect(tl.teach.length).toBeGreaterThan(0);
      expect(tl.learn.length).toBeGreaterThan(0);
    }
  });

  it('never exceeds 5 members', () => {
    const seed = user('s', ['Math', 'Science', 'History'], ['English'], { joinedAt: NOW - 60_000 });
    const pool = Array.from({ length: 10 }, (_, i) => user(`p${i}`, ['English'], ['Programming'], { joinedAt: NOW - 1000 }));
    pool.push(user('m', ['Programming'], ['Math']));
    const group = amBuildGroup(seed, pool, ctx());
    expect(group).not.toBeNull();
    expect(group.length).toBeLessThanOrEqual(5);
    expect(group.length).toBeGreaterThanOrEqual(3);
  });

  it('returns null when fewer than 3 compatible users exist', () => {
    const a = user('a', ['Math'], ['English']);
    const b = user('b', ['English'], ['Math']);
    expect(amBuildGroup(a, [b], ctx())).toBeNull();
  });

  it('skips blocked members', () => {
    const a = user('a', ['Math'], ['English'], { joinedAt: NOW - 20_000 });
    const b = user('b', ['English'], ['Science']);
    const c = user('c', ['Science'], ['Math']);
    const blockSet = new Set(['a|c']);
    expect(amBuildGroup(a, [b, c], ctx({ blockSet }))).toBeNull();
  });

  it('respects group cooldown', () => {
    const a = user('a', ['Math'], ['English'], { joinedAt: NOW - 20_000 });
    const b = user('b', ['English'], ['Science']);
    const c = user('c', ['Science'], ['Math']);
    const cooldowns = amCreateCooldownIndex([
      { id: 'x', createdAt: NOW - 60_000, status: 'accepted', mode: 'peers', members: [{ userId: 'a', accepted: true }, { userId: 'b', accepted: true }] },
    ]);
    expect(amBuildGroup(a, [b, c], ctx({ cooldowns }))).toBeNull();
  });
});

describe('amPlanMatches', () => {
  it('pairs buddies and keeps every user in at most one proposal', () => {
    const users = [
      user('a', ['Math'], ['English'], { mode: 'buddy', joinedAt: NOW - 30_000 }),
      user('b', ['English'], ['Math'], { mode: 'buddy' }),
      user('c', ['English'], ['Math'], { mode: 'buddy' }),
      user('d', ['Math'], ['English'], { mode: 'buddy' }),
    ];
    const plan = amPlanMatches(users, ctx());
    expect(plan).toHaveLength(2);
    const ids = plan.flatMap((p) => p.memberIds);
    expect(new Set(ids).size).toBe(ids.length);
    expect(plan[0].memberIds).toContain('a');
  });

  it('ignores stale and non-waiting rows', () => {
    const users = [
      user('a', ['Math'], ['English'], { mode: 'buddy' }),
      user('b', ['English'], ['Math'], { mode: 'buddy', lastSeen: NOW - 60_000 }),
      user('c', ['English'], ['Math'], { mode: 'buddy', status: 'proposed' }),
    ];
    expect(amPlanMatches(users, ctx())).toHaveLength(0);
  });

  it('includes teach/learn per member', () => {
    const users = [user('a', ['Math'], ['English'], { mode: 'buddy' }), user('b', ['English'], ['Math'], { mode: 'buddy' })];
    const [p] = amPlanMatches(users, ctx());
    const a = p.members.find((m) => m.userId === 'a');
    expect(a.teach).toEqual(['English']);
    expect(a.learn).toEqual(['Math']);
  });
});
