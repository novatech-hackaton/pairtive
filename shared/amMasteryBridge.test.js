import { describe, expect, it } from 'vitest';
import fc from 'fast-check';
import { amBridgeMastery, amBridgeMatchesProfile } from './amMasteryBridge.js';

describe('amBridgeMastery', () => {
  it('maps Proficient to strong, Weak to weak, and ignores Developing', () => {
    const out = amBridgeMastery([
      { topic_name: 'Fractions', mastery_level: 'Proficient' },
      { topic_name: 'Algebra', mastery_level: 'Weak' },
      { topic_name: 'Geometry', mastery_level: 'Developing' },
    ]);
    expect(out).toEqual({ strong: ['Fractions'], weak: ['Algebra'] });
  });

  it('dedupes, sorts in code-unit order, and drops conflicting names from both lists', () => {
    const out = amBridgeMastery([
      { topic_name: 'b', mastery_level: 'Proficient' },
      { topic_name: 'B', mastery_level: 'Proficient' },
      { topic_name: 'B', mastery_level: 'Proficient' },
      { topic_name: 'Mixed', mastery_level: 'Proficient' },
      { topic_name: 'Mixed', mastery_level: 'Weak' },
      { topic_name: 'z', mastery_level: 'Weak' },
      { topic_name: 'A', mastery_level: 'Weak' },
    ]);
    expect(out).toEqual({ strong: ['B', 'b'], weak: ['A', 'z'] });
  });

  it('accepts nested topics(topic_name) and empty input', () => {
    expect(amBridgeMastery([{ topics: { topic_name: 'Ratios' }, mastery_level: 'Weak' }])).toEqual({
      strong: [],
      weak: ['Ratios'],
    });
    expect(amBridgeMastery([])).toEqual({ strong: [], weak: [] });
    expect(amBridgeMastery(null)).toEqual({ strong: [], weak: [] });
  });
});

describe('amBridgeMatchesProfile', () => {
  const bridged = { strong: ['A', 'B'], weak: ['C'] };

  it('is true only for a diagnostic profile with identical arrays in order', () => {
    expect(
      amBridgeMatchesProfile({ subjects_source: 'diagnostic', strong_subjects: ['A', 'B'], weak_subjects: ['C'] }, bridged),
    ).toBe(true);
    expect(
      amBridgeMatchesProfile({ subjects_source: 'onboarding', strong_subjects: ['A', 'B'], weak_subjects: ['C'] }, bridged),
    ).toBe(false);
    expect(
      amBridgeMatchesProfile({ subjects_source: 'diagnostic', strong_subjects: ['B', 'A'], weak_subjects: ['C'] }, bridged),
    ).toBe(false);
    expect(amBridgeMatchesProfile(null, bridged)).toBe(false);
  });

  it('treats null/undefined profile arrays as empty', () => {
    expect(
      amBridgeMatchesProfile({ subjects_source: 'diagnostic', strong_subjects: null }, { strong: [], weak: [] }),
    ).toBe(true);
    expect(amBridgeMatchesProfile({ subjects_source: 'diagnostic' }, bridged)).toBe(false);
  });
});

// Feature: skillgps-matching-integration, Property 7: Bridge derivation
describe('Property 7: Bridge derivation', () => {
  /**
   * **Validates: Requirements 5.1, 5.2, 5.3, 5.7**
   */
  const amLevel = fc.constantFrom('Proficient', 'Developing', 'Weak');
  // A small fixed pool forces duplicate names with conflicting levels; free-form strings
  // (including non-ASCII) exercise code-unit ordering.
  const amName = fc.oneof(
    fc.constantFrom('Algebra', 'algebra', 'Fractions', 'Geometry', 'Ratios', 'B', 'b', 'Ä'),
    fc.string({ maxLength: 6, unit: 'binary' }),
  );
  const amRecord = fc.record({ topic_name: amName, mastery_level: amLevel });

  const amStrictlyAscending = (xs) => xs.every((x, i) => i === 0 || xs[i - 1] < x);

  it('strong/weak equal sort(P \\ W) and sort(W \\ P) in code-unit order', () => {
    fc.assert(
      fc.property(fc.array(amRecord, { maxLength: 30 }), (records) => {
        const { strong, weak } = amBridgeMastery(records);

        const levels = new Map();
        for (const r of records) {
          if (!levels.has(r.topic_name)) levels.set(r.topic_name, new Set());
          levels.get(r.topic_name).add(r.mastery_level);
        }
        const strongSet = new Set(strong);
        const weakSet = new Set(weak);

        // Disjoint, sorted strictly ascending (implies duplicate-free).
        expect(strong.some((s) => weakSet.has(s))).toBe(false);
        expect(amStrictlyAscending(strong)).toBe(true);
        expect(amStrictlyAscending(weak)).toBe(true);

        // Every output name is backed by the right records and none of the opposite level.
        for (const s of strong) {
          expect(levels.get(s)?.has('Proficient')).toBe(true);
          expect(levels.get(s).has('Weak')).toBe(false);
        }
        for (const w of weak) {
          expect(levels.get(w)?.has('Weak')).toBe(true);
          expect(levels.get(w).has('Proficient')).toBe(false);
        }

        // Completeness: Proficient-without-Weak → strong, Weak-without-Proficient → weak,
        // Developing-only → neither.
        for (const [name, set] of levels) {
          const p = set.has('Proficient');
          const w = set.has('Weak');
          expect(strongSet.has(name)).toBe(p && !w);
          expect(weakSet.has(name)).toBe(w && !p);
        }
      }),
      { numRuns: 100 },
    );
  });
});

// Feature: skillgps-matching-integration, Property 8: Bridge idempotence
describe('Property 8: Bridge idempotence', () => {
  /**
   * **Validates: Requirements 5.4**
   */
  const amLevel = fc.constantFrom('Proficient', 'Developing', 'Weak');
  const amName = fc.oneof(
    fc.constantFrom('Algebra', 'algebra', 'Fractions', 'Geometry', 'Ratios', 'B', 'b', 'Ä'),
    fc.string({ maxLength: 6, unit: 'binary' }),
  );
  // Mix flat and nested topics(topic_name) shapes, as the provider may see either.
  const amRecord = fc.oneof(
    fc.record({ topic_name: amName, mastery_level: amLevel }),
    fc.record({ topics: fc.record({ topic_name: amName }), mastery_level: amLevel }),
  );
  // A record list plus a full permutation of it.
  const amRecordsAndShuffle = fc
    .array(amRecord, { maxLength: 30 })
    .chain((records) =>
      fc.tuple(
        fc.constant(records),
        fc.shuffledSubarray(records, { minLength: records.length, maxLength: records.length }),
      ),
    );
  // Starting profile: onboarding-sourced with arbitrary subjects, or already diagnostic.
  const amStartProfile = fc.record({
    subjects_source: fc.constantFrom('onboarding', 'diagnostic'),
    strong_subjects: fc.option(fc.array(amName, { maxLength: 5 }), { nil: null }),
    weak_subjects: fc.option(fc.array(amName, { maxLength: 5 }), { nil: null }),
  });

  // JS model of the RPC write: replace both arrays and mark the profile diagnostic-sourced.
  const amApply = (profile, records) => {
    const { strong, weak } = amBridgeMastery(records);
    return { ...profile, subjects_source: 'diagnostic', strong_subjects: strong, weak_subjects: weak };
  };

  it('is deterministic, order-independent, and stable under re-application', () => {
    fc.assert(
      fc.property(amRecordsAndShuffle, amStartProfile, ([records, shuffled], start) => {
        const once = amBridgeMastery(records);

        // (a) Same input → same output; any permutation → identical output.
        expect(amBridgeMastery(records)).toEqual(once);
        expect(amBridgeMastery(shuffled)).toEqual(once);

        // Applying twice equals applying once.
        const applied = amApply(start, records);
        const appliedTwice = amApply(applied, records);
        expect(appliedTwice.strong_subjects).toEqual(applied.strong_subjects);
        expect(appliedTwice.weak_subjects).toEqual(applied.weak_subjects);
        expect(appliedTwice.subjects_source).toBe('diagnostic');

        // (b) The applied profile matches → self-heal does not fire again, even after a reshuffle.
        expect(amBridgeMatchesProfile(applied, once)).toBe(true);
        expect(amBridgeMatchesProfile(applied, amBridgeMastery(shuffled))).toBe(true);
        expect(
          amBridgeMatchesProfile(
            { subjects_source: 'diagnostic', strong_subjects: once.strong, weak_subjects: once.weak },
            once,
          ),
        ).toBe(true);

        // (c) Same arrays but onboarding-sourced → not a match, so the bridge must still run.
        expect(
          amBridgeMatchesProfile(
            { subjects_source: 'onboarding', strong_subjects: once.strong, weak_subjects: once.weak },
            once,
          ),
        ).toBe(false);
      }),
      { numRuns: 100 },
    );
  });
});
