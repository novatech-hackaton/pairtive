// Study Peers (3-5) greedy group builder + the full matching planner.

import {
  AM_MATCH_CONFIG,
  AM_MODES,
  amBestBuddy,
  amCoverage,
  amHardFilter,
  amIsFresh,
  amIsSuspended,
  amOneWayAllowed,
  amSharesLanguage,
  amSmoothedRating,
  amSmoothedSuccess,
  amTeachLearn,
  amWaitMs,
} from './amMatchScore.js';

const clamp01 = (n) => Math.max(0, Math.min(1, n));

/** Every member learns something (weak covered). Strict mode also requires every member to teach something. */
export function amGroupSatisfied(group, relaxed) {
  return group.every((m) => {
    const others = group.filter((o) => o.id !== m.id);
    const { teach, learn } = amTeachLearn(m, others);
    return relaxed ? teach.length > 0 || learn.length > 0 : teach.length > 0 && learn.length > 0;
  });
}

export function amAllWeakCovered(group) {
  return group.every((m) => amTeachLearn(m, group.filter((o) => o.id !== m.id)).learn.length > 0);
}

/** Marginal value of adding `cand` to `group`. */
export function amMarginalScore(group, cand, now, cfg = AM_MATCH_CONFIG) {
  const groupStrong = { strong: [...new Set(group.flatMap((m) => m.strong))] };
  const learnCov = amCoverage(cand, groupStrong);
  const uncovered = new Set(group.flatMap((m) => m.weak).filter((s) => !groupStrong.strong.includes(s)));
  let teachGain;
  if (uncovered.size > 0) {
    teachGain = cand.strong.filter((s) => uncovered.has(s)).length / uncovered.size;
  } else {
    const allWeak = new Set(group.flatMap((m) => m.weak));
    teachGain = cand.strong.some((s) => allWeak.has(s)) ? 0.5 : 0;
  }
  const parts = {
    reciprocity: (learnCov + teachGain) / 2,
    rating: amSmoothedRating(cand, cfg),
    success: amSmoothedSuccess(cand, cfg),
    wait: clamp01(amWaitMs(cand, now) / cfg.waitFullMs),
    language: group.filter((m) => amSharesLanguage(m, cand)).length / group.length,
  };
  const w = cfg.weights;
  const score =
    w.reciprocity * parts.reciprocity +
    w.rating * parts.rating +
    w.success * parts.success +
    w.wait * parts.wait +
    w.language * parts.language;
  return { score, parts, connects: learnCov > 0 || teachGain > 0 };
}

/**
 * Greedy: start with the seed (longest waiting), keep adding the best-scoring compatible
 * candidate until every member's weak subject is covered (and size >= 3) or size hits 5.
 */
export function amBuildGroup(seed, candidates, ctx, cfg = AM_MATCH_CONFIG) {
  const { now } = ctx;
  const relaxed = amOneWayAllowed([seed], now, cfg);
  const group = [seed];
  let pool = candidates.filter(
    (c) => c.id !== seed.id && c.mode === AM_MODES.peers && amHardFilter(seed, c, ctx, { requireCoverage: false }).ok,
  );

  while (group.length < cfg.peersMax) {
    const done = group.length >= cfg.peersMin && amAllWeakCovered(group) && amGroupSatisfied(group, relaxed);
    if (done) break;

    let best = null;
    for (const c of pool) {
      if (!group.every((m) => amHardFilter(m, c, ctx, { requireCoverage: false }).ok)) continue;
      const result = amMarginalScore(group, c, now, cfg);
      if (!result.connects) continue;
      const ids = [...group.map((m) => m.id), c.id];
      if (ids.length >= cfg.peersMin && ctx.cooldowns?.groupInCooldown(ids, now)) continue;
      if (!best || result.score > best.score || (result.score === best.score && c.joinedAt < best.user.joinedAt)) {
        best = { user: c, score: result.score };
      }
    }
    if (!best) break;
    group.push(best.user);
    pool = pool.filter((c) => c.id !== best.user.id);
  }

  if (group.length < cfg.peersMin) return null;
  if (!amGroupSatisfied(group, relaxed)) return null;
  if (ctx.cooldowns?.groupInCooldown(group.map((m) => m.id), now)) return null;
  return group;
}

function amToProposal(mode, group) {
  return {
    mode,
    memberIds: group.map((m) => m.id),
    members: group.map((m) => ({ userId: m.id, ...amTeachLearn(m, group.filter((o) => o.id !== m.id)) })),
  };
}

/**
 * Plan as many matches as possible from the waiting queue.
 * Seeds are processed longest-waiting first; each user appears in at most one proposal.
 */
export function amPlanMatches(users, ctx, cfg = AM_MATCH_CONFIG) {
  const { now } = ctx;
  const waiting = users
    .filter((u) => u.status === 'waiting' && amIsFresh(u, now, cfg) && !amIsSuspended(u, now))
    .sort((a, b) => a.joinedAt - b.joinedAt);
  const used = new Set();
  const proposals = [];

  for (const seed of waiting) {
    if (used.has(seed.id)) continue;
    const pool = waiting.filter((u) => !used.has(u.id) && u.id !== seed.id && u.mode === seed.mode);
    if (seed.mode === AM_MODES.buddy) {
      const best = amBestBuddy(seed, pool, ctx, cfg);
      if (!best) continue;
      const group = [seed, best.user];
      group.forEach((m) => used.add(m.id));
      proposals.push({ ...amToProposal(AM_MODES.buddy, group), score: best.result.score });
    } else {
      const group = amBuildGroup(seed, pool, ctx, cfg);
      if (!group) continue;
      group.forEach((m) => used.add(m.id));
      proposals.push(amToProposal(AM_MODES.peers, group));
    }
  }
  return proposals;
}
