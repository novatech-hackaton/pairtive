/**
 * Recommendation_Engine — deterministic, rule-based selection and ordering of
 * recommendation entries. It never calls Gemini or any network; its selection
 * and order never depend on generated wording.
 *
 * `buildRecommendations(assessedTopics)` takes rows shaped like
 * `{ topicId, topicName, masteryProbability, masteryLevel }` and returns an
 * ordered list of entries, each with the deterministic recommendationContent
 * attached (used as grounding + fallback).
 *
 * Order: all Weak first, then Developing, then Proficient; within a level by
 * ascending masteryProbability, then topic name (case-insensitive), then topic
 * id ascending. Deterministic regardless of input order.
 */
import { getRecommendationContent } from '../data/dsRecommendationContent.js';

const LEVEL_RANK = { Weak: 0, Developing: 1, Proficient: 2 };

export function buildRecommendations(assessedTopics) {
  const rows = Array.isArray(assessedTopics) ? assessedTopics.slice() : [];

  const entries = rows.map((r) => ({
    topicId: r.topicId,
    topicName: r.topicName,
    masteryProbability: typeof r.masteryProbability === 'number' ? r.masteryProbability : 0,
    masteryLevel: r.masteryLevel,
    recommendationContent: getRecommendationContent(r.topicName),
  }));

  entries.sort((a, b) => {
    const ra = LEVEL_RANK[a.masteryLevel] ?? 1;
    const rb = LEVEL_RANK[b.masteryLevel] ?? 1;
    if (ra !== rb) return ra - rb;
    if (a.masteryProbability !== b.masteryProbability) return a.masteryProbability - b.masteryProbability;
    const na = String(a.topicName ?? '').toLowerCase();
    const nb = String(b.topicName ?? '').toLowerCase();
    if (na !== nb) return na < nb ? -1 : 1;
    return String(a.topicId) < String(b.topicId) ? -1 : String(a.topicId) > String(b.topicId) ? 1 : 0;
  });

  return entries;
}

export default buildRecommendations;
