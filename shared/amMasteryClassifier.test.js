import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import fc from 'fast-check';
import {
  amClassifyMastery,
  amIsClassificationError,
  AM_MASTERY_LEVELS,
  __amResetWarningLatchForTests,
} from './amMasteryClassifier.js';

const RANK = { Weak: 0, Developing: 1, Proficient: 2 };

// Ported from modules/diagnostic-skillgps/frontend/src/lib/dsMasteryClassifier.test.js
describe('amClassifyMastery (examples)', () => {
  beforeEach(() => __amResetWarningLatchForTests());

  it('maps below 0.40 to Weak', () => {
    expect(amClassifyMastery(0)).toBe('Weak');
    expect(amClassifyMastery(0.39)).toBe('Weak');
  });

  it('maps [0.40, 0.70) to Developing', () => {
    expect(amClassifyMastery(0.4)).toBe('Developing');
    expect(amClassifyMastery(0.69)).toBe('Developing');
  });

  it('maps >= 0.70 to Proficient', () => {
    expect(amClassifyMastery(0.7)).toBe('Proficient');
    expect(amClassifyMastery(1)).toBe('Proficient');
  });

  it('handles values immediately around the 0.4 / 0.7 boundaries', () => {
    const below = (x) => x - Number.EPSILON;
    expect(amClassifyMastery(below(0.4))).toBe('Weak');
    expect(amClassifyMastery(0.4)).toBe('Developing');
    expect(amClassifyMastery(below(0.7))).toBe('Developing');
    expect(amClassifyMastery(0.7)).toBe('Proficient');
  });

  it('returns a Classification_Error (not thrown) for non-finite input', () => {
    const r = amClassifyMastery(Number.NaN);
    expect(amIsClassificationError(r)).toBe(true);
    expect(amClassifyMastery(Infinity).error).toBe(true);
    expect(amClassifyMastery('x').error).toBe(true);
  });

  it('returns a Classification_Error for out-of-range input', () => {
    expect(amClassifyMastery(-0.1).error).toBe(true);
    expect(amClassifyMastery(1.1).error).toBe(true);
  });

  it('is monotonic: p1 <= p2 implies level(p1) <= level(p2)', () => {
    const ps = [0, 0.1, 0.39, 0.4, 0.55, 0.69, 0.7, 0.9, 1];
    for (let i = 1; i < ps.length; i += 1) {
      expect(RANK[amClassifyMastery(ps[i])]).toBeGreaterThanOrEqual(RANK[amClassifyMastery(ps[i - 1])]);
    }
  });

  it('exposes the three levels in rank order', () => {
    expect(AM_MASTERY_LEVELS).toEqual(['Weak', 'Developing', 'Proficient']);
  });
});

describe('amClassifyMastery invalid threshold config', () => {
  let warn;
  beforeEach(() => {
    __amResetWarningLatchForTests();
    warn = vi.spyOn(console, 'warn').mockImplementation(() => {});
  });
  afterEach(() => warn.mockRestore());

  it('falls back to 0.40 / 0.70 and warns once per load', () => {
    const bad = { developing: 0.8, proficient: 0.2 };
    expect(amClassifyMastery(0.39, bad)).toBe('Weak');
    expect(amClassifyMastery(0.4, bad)).toBe('Developing');
    expect(amClassifyMastery(0.7, bad)).toBe('Proficient');
    expect(warn).toHaveBeenCalledTimes(1);
  });
});

// Feature: skillgps-matching-integration, Property 3: Classifier thresholds and monotonicity
// **Validates: Requirements 2.4**
describe('Property 3: Classifier thresholds and monotonicity', () => {
  const unit = fc.double({ min: 0, max: 1, noNaN: true });
  // Mix uniform values with the exact boundaries and their float neighbours.
  const unitWithBoundaries = fc.oneof(
    unit,
    fc.constantFrom(0, 0.4, 0.7, 1, 0.4 - Number.EPSILON, 0.7 - Number.EPSILON, 0.4 + Number.EPSILON, 0.7 + Number.EPSILON),
  );

  it('Weak iff p < 0.40, Developing iff 0.40 <= p < 0.70, Proficient iff p >= 0.70', () => {
    fc.assert(
      fc.property(unitWithBoundaries, (p) => {
        const level = amClassifyMastery(p);
        expect(level === 'Weak').toBe(p < 0.4);
        expect(level === 'Developing').toBe(p >= 0.4 && p < 0.7);
        expect(level === 'Proficient').toBe(p >= 0.7);
      }),
      { numRuns: 200 },
    );
  });

  it('is monotonic: p1 <= p2 implies rank(level(p1)) <= rank(level(p2))', () => {
    fc.assert(
      fc.property(unitWithBoundaries, unitWithBoundaries, (a, b) => {
        const [p1, p2] = a <= b ? [a, b] : [b, a];
        expect(RANK[amClassifyMastery(p1)]).toBeLessThanOrEqual(RANK[amClassifyMastery(p2)]);
      }),
      { numRuns: 200 },
    );
  });

  it('returns an error object for non-finite or out-of-range input', () => {
    const invalid = fc.oneof(
      fc.constantFrom(Number.NaN, Infinity, -Infinity),
      fc.double({ max: -Number.MIN_VALUE, noNaN: true }), // excludes -0, which is a valid 0
      fc.double({ min: 1, minExcluded: true, noNaN: true }),
      fc.oneof(fc.string(), fc.boolean(), fc.constant(null), fc.constant(undefined), fc.object()),
    );
    fc.assert(
      fc.property(invalid, (v) => {
        const r = amClassifyMastery(v);
        expect(amIsClassificationError(r)).toBe(true);
        expect(typeof r.reason).toBe('string');
        expect(Object.is(r.value, v)).toBe(true);
      }),
      { numRuns: 200 },
    );
  });
});
