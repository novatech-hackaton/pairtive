// Recommendation_Engine: deterministic, rule-based selection and ordering of
// recommendation entries. Ported from the diagnostic-skillgps module
// (lib/dsRecommendationEngine.js). No network calls; the Gemini service is out of scope.
//
// amBuildRecommendations(rows) accepts rows shaped like
//   { topicId, topicName, masteryProbability, masteryLevel }
// or Mastery_Records shaped like
//   { topic_id, topic_name, mastery_probability, mastery_level }
// and returns entries { topicId, topicName, masteryProbability, masteryLevel,
// recommendationContent }.
//
// Order: Weak, then Developing, then Proficient; within a level by ascending
// masteryProbability, then case-insensitive topic name, then topic id. The result
// does not depend on input order.

import { AM_MASTERY_LEVELS } from './amMasteryClassifier.js';
import { amGetRecommendationContent } from './amRecommendationContent.js';

// Weak -> 0, Developing -> 1, Proficient -> 2.
const AM_LEVEL_RANK = Object.freeze(
  Object.fromEntries(AM_MASTERY_LEVELS.map((level, i) => [level, i])),
);
// Unknown levels sort with Developing, as in the original engine.
const AM_UNKNOWN_RANK = AM_LEVEL_RANK.Developing;

const amCmp = (a, b) => (a < b ? -1 : a > b ? 1 : 0);

function amPick(row, camel, snake) {
  return row[camel] !== undefined ? row[camel] : row[snake];
}

function amToEntry(row) {
  const r = row && typeof row === 'object' ? row : {};
  const topicName = amPick(r, 'topicName', 'topic_name');
  const p = amPick(r, 'masteryProbability', 'mastery_probability');
  return {
    topicId: amPick(r, 'topicId', 'topic_id'),
    topicName,
    // Non-finite values (including NaN) become 0 so the comparator stays total.
    masteryProbability: typeof p === 'number' && Number.isFinite(p) ? p : 0,
    masteryLevel: amPick(r, 'masteryLevel', 'mastery_level'),
    recommendationContent: amGetRecommendationContent(topicName),
  };
}

function amCompareEntries(a, b) {
  const ra = AM_LEVEL_RANK[a.masteryLevel] ?? AM_UNKNOWN_RANK;
  const rb = AM_LEVEL_RANK[b.masteryLevel] ?? AM_UNKNOWN_RANK;
  if (ra !== rb) return ra - rb;
  if (a.masteryProbability !== b.masteryProbability) return a.masteryProbability - b.masteryProbability;
  const byName = amCmp(String(a.topicName ?? '').toLowerCase(), String(b.topicName ?? '').toLowerCase());
  if (byName !== 0) return byName;
  const byId = amCmp(String(a.topicId ?? ''), String(b.topicId ?? ''));
  if (byId !== 0) return byId;
  // Last resort so names differing only in case still order the same way every time.
  return amCmp(String(a.topicName ?? ''), String(b.topicName ?? ''));
}

/** Build the ordered recommendation list. Never mutates the input. */
export function amBuildRecommendations(rows) {
  const list = Array.isArray(rows) ? rows : [];
  return list.map(amToEntry).sort(amCompareEntries);
}

export default amBuildRecommendations;
