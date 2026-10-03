// Pairtive AI matching core: hard filters, scoring, cooldowns and copy.
// Pure JS (no I/O) so the API, scripts and tests share a single source of truth.

import { amSchoolKey } from './amSubjects.js';

export const AM_MATCH_CONFIG = Object.freeze({
  // Score weights (sum = 1)
  weights: Object.freeze({ reciprocity: 0.4, rating: 0.25, success: 0.2, wait: 0.1, language: 0.05 }),
  // Bayesian smoothing so newcomers start near an average score instead of last.
  ratingPrior: 3.5,
  ratingPriorWeight: 5,
  successPrior: 0.75,
  successPriorWeight: 5,
  // Timing
  staleMs: 30_000, // heartbeat older than this = not waiting anymore
  relaxAfterMs: 30_000, // one-way matches allowed after this much waiting
  waitFullMs: 60_000, // wait component reaches 1.0 at this wait time
  cooldownMs: 24 * 60 * 60 * 1000,
  cooldownMatches: 5, // ...or until both users had this many other matches
  // Group sizes
  buddySize: 2,
  peersMin: 3,
  peersMax: 5,
  proposalTtlMs: 15_000,
});

export const AM_MODES = Object.freeze({ buddy: 'buddy', peers: 'peers' });

const toMs = (v) => (v == null ? 0 : typeof v === 'number' ? v : new Date(v).getTime());
const clamp01 = (n) => Math.max(0, Math.min(1, n));

/** Convert a match_queue row + profile row into the matcher's user shape. */
export function amNormalizeUser(queueRow, profile) {
  return {
    id: queueRow.user_id,
    mode: queueRow.mode,
    sameSchoolOnly: !!queueRow.same_school_only,
    joinedAt: toMs(queueRow.joined_at),
    lastSeen: toMs(queueRow.last_seen),
    status: queueRow.status ?? 'waiting',
    name: profile?.name ?? 'Student',
    weak: profile?.weak_subjects ?? [],
    strong: profile?.strong_subjects ?? [],
    languages: profile?.languages ?? [],
    school: profile?.school ?? '',
    ratingAvg: Number(profile?.rating_avg ?? 0),
    ratingCount: Number(profile?.rating_count ?? 0),
    successCount: Number(profile?.success_count ?? 0),
    sessionsCount: Number(profile?.sessions_count ?? 0),
    suspendedUntil: profile?.status === 'suspended' ? toMs(profile?.suspended_until) : 0,
  };
}

export const amPairKey = (a, b) => (a < b ? `${a}|${b}` : `${b}|${a}`);

/** blocks: [{ blocker_id, blocked_id }] -> Set of pair keys (either direction blocks both). */
export function amBuildBlockSet(blocks = []) {
  const set = new Set();
  for (const b of blocks) set.add(amPairKey(b.blocker_id, b.blocked_id));
  return set;
}

export function amSmoothedRating(user, cfg = AM_MATCH_CONFIG) {
  const n = user.ratingCount || 0;
  const avg = n > 0 ? user.ratingAvg : 0;
  const smoothed = (cfg.ratingPrior * cfg.ratingPriorWeight + avg * n) / (cfg.ratingPriorWeight + n);
  return clamp01((smoothed - 1) / 4); // 1..5 stars -> 0..1
}

export function amSmoothedSuccess(user, cfg = AM_MATCH_CONFIG) {
  const n = user.sessionsCount || 0;
  const s = Math.min(user.successCount || 0, n);
  return clamp01((cfg.successPrior * cfg.successPriorWeight + s) / (cfg.successPriorWeight + n));
}

/** Fraction of learner's weak subjects that teacher is strong in. */
export function amCoverage(learner, teacher) {
  if (!learner.weak?.length) return 0;
  const strong = new Set(teacher.strong ?? []);
  return learner.weak.filter((s) => strong.has(s)).length / learner.weak.length;
}

export function amSharesLanguage(a, b) {
  const set = new Set((a.languages ?? []).map((l) => l.toLowerCase()));
  return (b.languages ?? []).some((l) => set.has(l.toLowerCase()));
}

export const amIsFresh = (user, now, cfg = AM_MATCH_CONFIG) => now - user.lastSeen <= cfg.staleMs;
export const amIsSuspended = (user, now) => !!user.suspendedUntil && user.suspendedUntil > now;
export const amWaitMs = (user, now) => Math.max(0, now - user.joinedAt);

export function amSchoolOk(a, b) {
  if (!a.sameSchoolOnly && !b.sameSchoolOnly) return true;
  const ka = amSchoolKey(a.school);
  return ka.length > 0 && ka === amSchoolKey(b.school);
}

/**
 * Cooldown index built from recent proposals (= matches).
 * history: [{ id, createdAt, status, mode, members: [{ userId, accepted }] }]
 * - Any proposal that was declined / expired puts every pair involving a non-acceptor in cooldown.
 * - Accepted proposals (real sessions): pair cooldown for Study Buddy matching,
 *   group rule (>= half the new group already shared a session) for Study Peers.
 * - Cooldown lifts after 24h OR once both users had `cooldownMatches` other matches since.
 */
export function amCreateCooldownIndex(history = [], cfg = AM_MATCH_CONFIG) {
  const proposals = history
    .map((p) => ({ ...p, createdAt: toMs(p.createdAt ?? p.created_at) }))
    .sort((a, b) => a.createdAt - b.createdAt);
  const byUser = new Map();
  for (const p of proposals) {
    for (const m of p.members) {
      if (!byUser.has(m.userId)) byUser.set(m.userId, []);
      byUser.get(m.userId).push(p.createdAt);
    }
  }

  const matchesSince = (userId, t) => (byUser.get(userId) ?? []).filter((x) => x > t).length;
  const lifted = (ids, t, now) =>
    now - t >= cfg.cooldownMs || ids.every((id) => matchesSince(id, t) >= cfg.cooldownMatches);

  function pairBlockingProposal(p, a, b, mode) {
    const ma = p.members.find((m) => m.userId === a);
    const mb = p.members.find((m) => m.userId === b);
    if (!ma || !mb) return false;
    if (p.status === 'accepted') return mode === AM_MODES.buddy;
    if (p.status === 'pending') return false;
    // declined / expired: cooldown when either of the two did not accept
    return ma.accepted !== true || mb.accepted !== true;
  }

  return {
    matchesSince,
    inPairCooldown(a, b, now, mode = AM_MODES.buddy) {
      for (let i = proposals.length - 1; i >= 0; i--) {
        const p = proposals[i];
        if (now - p.createdAt >= cfg.cooldownMs) break;
        if (pairBlockingProposal(p, a, b, mode) && !lifted([a, b], p.createdAt, now)) return true;
      }
      return false;
    },
    groupInCooldown(ids, now) {
      for (const p of proposals) {
        if (p.status !== 'accepted' || now - p.createdAt >= cfg.cooldownMs) continue;
        const shared = ids.filter((id) => p.members.some((m) => m.userId === id));
        if (shared.length >= 2 && shared.length * 2 >= ids.length && !lifted(shared, p.createdAt, now)) return true;
      }
      return false;
    },
  };
}

/** Hard filters every pair must pass. Returns { ok, reason }. */
export function amHardFilter(a, b, ctx, opts = {}) {
  const { now, blockSet, cooldowns } = ctx;
  const mode = a.mode;
  if (a.id === b.id) return { ok: false, reason: 'self' };
  if (a.mode !== b.mode) return { ok: false, reason: 'mode' };
  if (!amIsFresh(a, now) || !amIsFresh(b, now)) return { ok: false, reason: 'stale' };
  if (amIsSuspended(a, now) || amIsSuspended(b, now)) return { ok: false, reason: 'suspended' };
  if (blockSet?.has(amPairKey(a.id, b.id))) return { ok: false, reason: 'blocked' };
  if (!amSchoolOk(a, b)) return { ok: false, reason: 'school' };
  if (cooldowns?.inPairCooldown(a.id, b.id, now, mode)) return { ok: false, reason: 'cooldown' };
  if (opts.requireCoverage !== false && amCoverage(a, b) === 0 && amCoverage(b, a) === 0) {
    return { ok: false, reason: 'no-overlap' };
  }
  return { ok: true };
}

export function amOneWayAllowed(users, now, cfg = AM_MATCH_CONFIG) {
  return users.some((u) => amWaitMs(u, now) >= cfg.relaxAfterMs);
}

/** Score a Study Buddy candidate for a seed user. Returns null when filtered out. */
export function amScoreCandidate(seed, cand, ctx, cfg = AM_MATCH_CONFIG) {
  const filter = amHardFilter(seed, cand, ctx);
  if (!filter.ok) return null;
  const covSeed = amCoverage(seed, cand);
  const covCand = amCoverage(cand, seed);
  const twoWay = covSeed > 0 && covCand > 0;
  if (!twoWay && !amOneWayAllowed([seed, cand], ctx.now, cfg)) return null;

  const parts = {
    reciprocity: (covSeed + covCand) / 2,
    rating: amSmoothedRating(cand, cfg),
    success: amSmoothedSuccess(cand, cfg),
    wait: clamp01(amWaitMs(cand, ctx.now) / cfg.waitFullMs),
    language: amSharesLanguage(seed, cand) ? 1 : 0,
  };
  const w = cfg.weights;
  const score =
    w.reciprocity * parts.reciprocity +
    w.rating * parts.rating +
    w.success * parts.success +
    w.wait * parts.wait +
    w.language * parts.language;
  return { score, parts, twoWay };
}

export function amRankCandidates(seed, candidates, ctx, cfg = AM_MATCH_CONFIG) {
  return candidates
    .map((c) => ({ user: c, result: amScoreCandidate(seed, c, ctx, cfg) }))
    .filter((x) => x.result)
    .sort((x, y) => y.result.score - x.result.score || x.user.joinedAt - y.user.joinedAt);
}

export function amBestBuddy(seed, candidates, ctx, cfg = AM_MATCH_CONFIG) {
  return amRankCandidates(seed, candidates, ctx, cfg)[0] ?? null;
}

/** What a member teaches / learns inside a given group. */
export function amTeachLearn(member, others) {
  const othersWeak = new Set(others.flatMap((o) => o.weak ?? []));
  const othersStrong = new Set(others.flatMap((o) => o.strong ?? []));
  return {
    teach: (member.strong ?? []).filter((s) => othersWeak.has(s)),
    learn: (member.weak ?? []).filter((s) => othersStrong.has(s)),
  };
}

const amJoinNames = (names) =>
  names.length <= 1 ? names[0] ?? '' : `${names.slice(0, -1).join(', ')} & ${names[names.length - 1]}`;

/**
 * Friendly preview copy, e.g.
 *   { teach: [{ subject: 'Math', names: ['Ana'], text: "You'll help Ana with Math" }], learn: [...] }
 */
export function amTeachLearnCopy(me, others) {
  const teachMap = new Map();
  const learnMap = new Map();
  for (const o of others) {
    for (const s of me.strong ?? []) {
      if ((o.weak ?? []).includes(s)) teachMap.set(s, [...(teachMap.get(s) ?? []), o.name]);
    }
    for (const s of me.weak ?? []) {
      if ((o.strong ?? []).includes(s)) learnMap.set(s, [...(learnMap.get(s) ?? []), o.name]);
    }
  }
  const teach = [...teachMap].map(([subject, names]) => ({
    subject,
    names,
    text: `You'll help ${amJoinNames(names)} with ${subject}`,
  }));
  const learn = [...learnMap].map(([subject, names]) => ({
    subject,
    names,
    text: `${amJoinNames(names)} will help you with ${subject}`,
  }));
  let headline = 'Study together and swap what you know';
  if (teach.length && learn.length) headline = "A perfect swap: you teach, they teach you back";
  else if (teach.length) headline = 'Your turn to shine: you get to be the tutor';
  else if (learn.length) headline = "Time to level up: you're learning this round";
  return { teach, learn, headline };
}
