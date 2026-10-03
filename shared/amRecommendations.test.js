import { describe, expect, it } from 'vitest';
import fc from 'fast-check';
import { amBuildRecommendations } from './amRecommendations.js';
import { amGetRecommendationContent } from './amRecommendationContent.js';

describe('amGetRecommendationContent', () => {
  it('returns the predefined text with a case-insensitive, trimmed lookup', () => {
    const exact = amGetRecommendationContent('Recursion');
    expect(exact).toMatch(/base cases/);
    expect(amGetRecommendationContent('  recursion ')).toBe(exact);
  });

  it('falls back to a non-empty generic text naming the topic', () => {
    expect(amGetRecommendationContent('Graph Theory')).toMatch(/Graph Theory/);
    expect(amGetRecommendationContent(undefined)).toMatch(/this topic/);
  });
});

describe('amBuildRecommendations', () => {
  const rows = [
    { topicId: 't3', topicName: 'Loops', masteryProbability: 0.85, masteryLevel: 'Proficient' },
    { topicId: 't1', topicName: 'Recursion', masteryProbability: 0.2, masteryLevel: 'Weak' },
    { topicId: 't2', topicName: 'Functions', masteryProbability: 0.55, masteryLevel: 'Developing' },
    { topicId: 't4', topicName: 'Arrays and Strings', masteryProbability: 0.1, masteryLevel: 'Weak' },
  ];

  it('orders Weak, then Developing, then Proficient, then p ascending', () => {
    expect(amBuildRecommendations(rows).map((e) => e.topicId)).toEqual(['t4', 't1', 't2', 't3']);
  });

  it('breaks ties by case-insensitive name, then id', () => {
    const tied = [
      { topicId: 'b', topicName: 'beta', masteryProbability: 0.3, masteryLevel: 'Weak' },
      { topicId: 'z', topicName: 'Alpha', masteryProbability: 0.3, masteryLevel: 'Weak' },
      { topicId: 'a', topicName: 'beta', masteryProbability: 0.3, masteryLevel: 'Weak' },
    ];
    expect(amBuildRecommendations(tied).map((e) => e.topicId)).toEqual(['z', 'a', 'b']);
  });

  it('is independent of input order and does not mutate the input', () => {
    const reversed = rows.slice().reverse();
    const snapshot = JSON.stringify(reversed);
    expect(amBuildRecommendations(reversed)).toEqual(amBuildRecommendations(rows));
    expect(JSON.stringify(reversed)).toBe(snapshot);
  });

  it('attaches recommendation content to each entry', () => {
    const [first] = amBuildRecommendations([rows[1]]);
    expect(first.recommendationContent).toBe(amGetRecommendationContent('Recursion'));
  });

  it('accepts snake_case Mastery_Records', () => {
    const out = amBuildRecommendations([
      { topic_id: 'x', topic_name: 'Loops', mastery_probability: 0.9, mastery_level: 'Proficient' },
      { topic_id: 'y', topic_name: 'Functions', mastery_probability: 0.3, mastery_level: 'Weak' },
    ]);
    expect(out.map((e) => [e.topicId, e.topicName, e.masteryProbability, e.masteryLevel])).toEqual([
      ['y', 'Functions', 0.3, 'Weak'],
      ['x', 'Loops', 0.9, 'Proficient'],
    ]);
  });

  it('returns [] for non-array input and treats non-finite p as 0', () => {
    expect(amBuildRecommendations(null)).toEqual([]);
    const [entry] = amBuildRecommendations([{ topicId: 'n', topicName: 'Loops', masteryProbability: NaN, masteryLevel: 'Weak' }]);
    expect(entry.masteryProbability).toBe(0);
  });
});

// Feature: skillgps-matching-integration, Property 6: Recommendation ordering is deterministic
// **Validates: Requirements 4.4**
describe('Property 6: Recommendation ordering is deterministic', () => {
  const AM_RANK = { Weak: 0, Developing: 1, Proficient: 2 };

  // Small pools so ties on level, p, name (incl. case-only differences) and id are common.
  const amRowArb = fc
    .record({
      id: fc.constantFrom('a', 'b', 'c', 'd', 'e'),
      name: fc.constantFrom('Loops', 'loops', 'Recursion', 'Functions', 'Arrays and Strings', 'alpha'),
      // `+ 0` normalises -0 so equal probabilities compare identically under toEqual.
      p: fc.oneof(fc.constantFrom(0, 0.25, 0.5, 1), fc.double({ min: 0, max: 1, noNaN: true })).map((v) => v + 0),
      level: fc.constantFrom('Weak', 'Developing', 'Proficient'),
      snake: fc.boolean(),
    })
    .map(({ id, name, p, level, snake }) =>
      snake
        ? { topic_id: id, topic_name: name, mastery_probability: p, mastery_level: level }
        : { topicId: id, topicName: name, masteryProbability: p, masteryLevel: level },
    );

  // A list of rows plus an arbitrary permutation of it.
  const amRowsAndShuffleArb = fc
    .array(amRowArb, { maxLength: 12 })
    .chain((rows) =>
      fc.tuple(fc.constant(rows), fc.shuffledSubarray(rows, { minLength: rows.length, maxLength: rows.length })),
    );

  const amNormalize = (r) =>
    'topic_id' in r
      ? { topicId: r.topic_id, topicName: r.topic_name, masteryProbability: r.mastery_probability, masteryLevel: r.mastery_level }
      : { topicId: r.topicId, topicName: r.topicName, masteryProbability: r.masteryProbability, masteryLevel: r.masteryLevel };

  const amKey = (e) => JSON.stringify([e.topicId, e.topicName, e.masteryProbability, e.masteryLevel]);

  // Returns true when `a` may precede `b` under the spec comparator.
  function amInOrder(a, b) {
    const ra = AM_RANK[a.masteryLevel];
    const rb = AM_RANK[b.masteryLevel];
    if (ra !== rb) return ra < rb;
    if (a.masteryProbability !== b.masteryProbability) return a.masteryProbability < b.masteryProbability;
    const na = a.topicName.toLowerCase();
    const nb = b.topicName.toLowerCase();
    if (na !== nb) return na < nb;
    return a.topicId <= b.topicId;
  }

  it('returns a sorted permutation of the input, identical for any shuffle, without mutating input', () => {
    fc.assert(
      fc.property(amRowsAndShuffleArb, ([rows, shuffled]) => {
        const rowsSnapshot = structuredClone(rows);
        const shuffledSnapshot = structuredClone(shuffled);

        const out = amBuildRecommendations(rows);

        // Permutation of the input (as normalised entries).
        expect(out.map(amKey).sort()).toEqual(rows.map(amNormalize).map(amKey).sort());

        // Consecutive entries respect the comparator.
        for (let i = 1; i < out.length; i += 1) {
          expect(amInOrder(out[i - 1], out[i])).toBe(true);
        }

        // Same sequence for any permutation of the input.
        expect(amBuildRecommendations(shuffled)).toEqual(out);

        // Input arrays and rows are unchanged.
        expect(rows).toEqual(rowsSnapshot);
        expect(shuffled).toEqual(shuffledSnapshot);
      }),
      { numRuns: 100 },
    );
  });
});
