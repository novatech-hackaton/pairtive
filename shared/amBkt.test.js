import { describe, it, expect } from 'vitest';
import fixture from '../tests/fixtures/amBktParity.json';
import { amBktRun, amBktProbabilities, amBktParamsFor } from './amBkt.js';
import { AM_BKT_DEFAULT, AM_BKT_SKILLS } from './amBktParams.js';

const AM_TOLERANCE = 1e-6;
const AM_LEVELS = ['Weak', 'Developing', 'Proficient'];

// Feature: skillgps-matching-integration, Property 1: BKT parity with the Python reference
describe('Property 1: BKT parity with the Python reference', () => {
  const { counts, entries } = fixture;
  const heldOut = entries.slice(0, counts.heldOut);

  it('has 720 held-out + 300 random + 20 default entries (1,040 total)', () => {
    expect(counts).toEqual({ heldOut: 720, random: 300, default: 20 });
    expect(counts.heldOut + counts.random + counts.default).toBe(1040);
    expect(entries).toHaveLength(1040);
  });

  it('covers every one of the 49 fitted topics in the held-out set', () => {
    const skillNames = Object.keys(AM_BKT_SKILLS);
    expect(skillNames).toHaveLength(49);
    const seen = new Set(heldOut.map((e) => e.topicName));
    for (const name of skillNames) expect(seen.has(name)).toBe(true);
  });

  it('matches mastery_probability and the probability triple within 1e-6 for every entry', () => {
    const failures = [];

    entries.forEach((entry, index) => {
      let params;
      if (entry.topicName === null) {
        params = AM_BKT_DEFAULT;
      } else {
        // Named entries must resolve to their fitted parameters, never the default.
        expect(Object.prototype.hasOwnProperty.call(AM_BKT_SKILLS, entry.topicName)).toBe(true);
        params = amBktParamsFor(entry.topicName);
        expect(params).toBe(AM_BKT_SKILLS[entry.topicName]);
      }

      const p = amBktRun(entry.responses, params);
      const triple = amBktProbabilities(p);

      const diffs = [Math.abs(p - entry.mastery_probability)];
      for (const level of AM_LEVELS) diffs.push(Math.abs(triple[level] - entry.probabilities[level]));
      if (diffs.some((d) => !(d <= AM_TOLERANCE))) {
        failures.push({ index, topicName: entry.topicName, responses: entry.responses, got: { p, triple }, want: entry });
      }
    });

    expect(failures.slice(0, 5)).toEqual([]);
    expect(failures).toHaveLength(0);
  });
});
