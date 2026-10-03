import { describe, it, expect } from 'vitest';
import fc from 'fast-check';
import { amSummarizeMastery } from './amMasterySummary.js';

const EMPTY = { total: 0, overallPct: 0, proficient: 0, developing: 0, weak: 0 };

describe('amSummarizeMastery', () => {
  it('counts stored levels and rounds the mean probability', () => {
    const r = amSummarizeMastery([
      { mastery_probability: 0.9, mastery_level: 'Proficient' },
      { mastery_probability: 0.55, mastery_level: 'Developing' },
      { mastery_probability: 0.2, mastery_level: 'Weak' },
      { mastery_probability: 0.1, mastery_level: 'Weak' },
    ]);
    // mean = 1.75 / 4 = 0.4375 -> 44
    expect(r).toEqual({ total: 4, overallPct: 44, proficient: 1, developing: 1, weak: 2 });
  });

  it('uses the stored level rather than re-classifying p', () => {
    const r = amSummarizeMastery([{ mastery_probability: 0.1, mastery_level: 'Proficient' }]);
    expect(r.proficient).toBe(1);
    expect(r.weak).toBe(0);
  });

  it('coerces numeric strings from Postgres numeric columns', () => {
    const r = amSummarizeMastery([
      { mastery_probability: '0.8000', mastery_level: 'Proficient' },
      { mastery_probability: '0.6', mastery_level: 'Developing' },
    ]);
    expect(r).toEqual({ total: 2, overallPct: 70, proficient: 1, developing: 1, weak: 0 });
  });

  it('returns zeros for empty, null or non-array input', () => {
    expect(amSummarizeMastery([])).toEqual(EMPTY);
    expect(amSummarizeMastery(null)).toEqual(EMPTY);
    expect(amSummarizeMastery(undefined)).toEqual(EMPTY);
    expect(amSummarizeMastery({})).toEqual(EMPTY);
  });

  it('keeps counts summing to total when a stored level is missing', () => {
    const r = amSummarizeMastery([
      { mastery_probability: 0.75 },
      { mastery_probability: null, mastery_level: 'bogus' },
    ]);
    expect(r.total).toBe(2);
    expect(r.proficient + r.developing + r.weak).toBe(2);
    expect(r.proficient).toBe(1);
    expect(r.overallPct).toBe(75); // missing p is excluded from the mean
  });
});

// Feature: skillgps-matching-integration, Property 5: Home summary counts and overall %
// **Validates: Requirements 4.5, 4.6**
describe('Property 5: Home summary counts and overall %', () => {
  const LEVELS = ['Proficient', 'Developing', 'Weak'];

  // p in [0, 1], sometimes delivered as a numeric string (Postgres `numeric` via supabase-js).
  const amProbArb = fc.double({ min: 0, max: 1, noNaN: true, noDefaultInfinity: true });
  const amRawProbArb = fc.oneof(
    amProbArb,
    amProbArb.map((p) => String(p)),
    amProbArb.map((p) => p.toFixed(4)),
  );
  const amRecordArb = fc.record({
    mastery_probability: amRawProbArb,
    mastery_level: fc.constantFrom(...LEVELS),
  });

  it('counts stored levels summing to total and rounds the mean probability', () => {
    fc.assert(
      fc.property(fc.array(amRecordArb, { minLength: 1, maxLength: 50 }), (records) => {
        const r = amSummarizeMastery(records);

        expect(r.total).toBe(records.length);
        expect(r.proficient + r.developing + r.weak).toBe(r.total);
        expect(r.proficient).toBe(records.filter((x) => x.mastery_level === 'Proficient').length);
        expect(r.developing).toBe(records.filter((x) => x.mastery_level === 'Developing').length);
        expect(r.weak).toBe(records.filter((x) => x.mastery_level === 'Weak').length);

        const mean =
          records.reduce((acc, x) => acc + Number(x.mastery_probability), 0) / records.length;
        expect(r.overallPct).toBe(Math.round(mean * 100));
        expect(r.overallPct).toBeGreaterThanOrEqual(0);
        expect(r.overallPct).toBeLessThanOrEqual(100);
      }),
      { numRuns: 100 },
    );
  });
});
