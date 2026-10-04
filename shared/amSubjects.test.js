import { describe, expect, it } from 'vitest';
import fc from 'fast-check';
import {
  AM_LANGUAGES,
  amIsProfileComplete,
  amSchoolKey,
  amValidateBasics,
  amValidateDiagnosticSubjects,
} from './amSubjects.js';

describe('amValidateBasics', () => {
  it('requires name, languages and school', () => {
    const errors = amValidateBasics({ name: ' ', languages: [], school: '' });
    expect(Object.keys(errors).sort()).toEqual(['languages', 'name', 'school']);
  });
  it('passes valid input', () => {
    expect(amValidateBasics({ name: 'Ana', languages: ['English'], school: 'UP Diliman' })).toEqual({});
  });
});

describe('profile helpers', () => {
  it('detects complete profiles', () => {
    const p = { onboarded: true, name: 'Ana', languages: ['English'], school: 'UPD', weak_subjects: ['Math'], strong_subjects: ['English'] };
    expect(amIsProfileComplete(p)).toBe(true);
    expect(amIsProfileComplete({ ...p, onboarded: false })).toBe(false);
  });
  it('does not require subjects: onboarded + valid basics + empty arrays is complete', () => {
    const p = { onboarded: true, name: 'Ana', languages: ['English'], school: 'UPD', weak_subjects: [], strong_subjects: [] };
    expect(amIsProfileComplete(p)).toBe(true);
    expect(amIsProfileComplete({ ...p, subjects_source: 'onboarding' })).toBe(true);
    expect(amIsProfileComplete({ ...p, weak_subjects: ['Math'] })).toBe(true);
    expect(amIsProfileComplete({ ...p, school: ' ' })).toBe(false);
  });
  it('still rejects malformed arrays for onboarding-sourced profiles', () => {
    const p = { onboarded: true, name: 'Ana', languages: ['English'], school: 'UPD', subjects_source: 'onboarding' };
    expect(amIsProfileComplete({ ...p, weak_subjects: ['Math', 'Math'], strong_subjects: [] })).toBe(false);
    expect(amIsProfileComplete({ ...p, weak_subjects: ['Math'], strong_subjects: ['Math'] })).toBe(false);
    expect(amIsProfileComplete({ ...p, weak_subjects: [' '], strong_subjects: [] })).toBe(false);
  });
  it('normalizes school names', () => {
    expect(amSchoolKey('  UP  Diliman! ')).toBe(amSchoolKey('up diliman'));
  });
});

describe('diagnostic-derived subjects (Req 5.6)', () => {
  const base = { onboarded: true, name: 'Ana', languages: ['English'], school: 'UPD', subjects_source: 'diagnostic' };
  const topics = ['Variables', 'Loops', 'Conditionals', 'Functions', 'Arrays', 'Recursion', 'Fractions', 'Algebra', 'Grammar', 'Photosynthesis'];

  it('treats zero entries as complete', () => {
    expect(amValidateDiagnosticSubjects([], [])).toBeNull();
    expect(amIsProfileComplete({ ...base, weak_subjects: [], strong_subjects: [] })).toBe(true);
  });
  it('accepts 10 topic names outside AM_SUBJECTS', () => {
    const p = { ...base, weak_subjects: topics.slice(0, 4), strong_subjects: topics.slice(4) };
    expect(amIsProfileComplete(p)).toBe(true);
    expect(amIsProfileComplete({ ...base, weak_subjects: [], strong_subjects: topics })).toBe(true);
  });
  it('rejects duplicates and weak/strong overlap', () => {
    expect(amValidateDiagnosticSubjects(['Loops', 'Loops'], [])).toMatch(/Duplicate/);
    expect(amIsProfileComplete({ ...base, weak_subjects: ['Loops', 'Loops'], strong_subjects: [] })).toBe(false);
    expect(amValidateDiagnosticSubjects(['Loops'], ['Loops'])).toMatch(/both/);
    expect(amIsProfileComplete({ ...base, weak_subjects: ['Loops'], strong_subjects: ['Loops'] })).toBe(false);
  });
  it('rejects non-string or blank entries and missing arrays', () => {
    expect(amValidateDiagnosticSubjects([' '], [])).toMatch(/Invalid/);
    expect(amValidateDiagnosticSubjects([1], [])).toMatch(/Invalid/);
    expect(amIsProfileComplete({ ...base, weak_subjects: null, strong_subjects: [] })).toBe(false);
  });
  it('still requires onboarding and valid basics', () => {
    expect(amIsProfileComplete({ ...base, onboarded: false, weak_subjects: [], strong_subjects: [] })).toBe(false);
    expect(amIsProfileComplete({ ...base, name: '', weak_subjects: [], strong_subjects: [] })).toBe(false);
  });
});

// Feature: skillgps-matching-integration, Property 10: Diagnostic profiles stay complete for any count
describe('Property 10: diagnostic profiles stay complete for any count', () => {
  /** Validates: Requirements 5.6 */
  const trimmedText = (min, max) =>
    fc
      .string({ minLength: min, maxLength: max })
      .map((s) => s.trim())
      .filter((s) => s.length >= min && s.length <= max);

  const basicsArb = fc.record({
    name: trimmedText(2, 60),
    languages: fc.uniqueArray(fc.constantFrom(...AM_LANGUAGES), { minLength: 1, maxLength: 5 }),
    school: trimmedText(2, 120),
  });

  const topicArb = fc.string({ minLength: 1, maxLength: 40 }).filter((s) => s.trim().length > 0);

  // One unique pool split into weak/strong guarantees disjoint, duplicate-free arrays of 0–49 each.
  const disjointTopicsArb = fc.uniqueArray(topicArb, { maxLength: 98 }).chain((pool) =>
    fc
      .integer({ min: Math.max(0, pool.length - 49), max: Math.min(49, pool.length) })
      .map((k) => ({ weak: pool.slice(0, k), strong: pool.slice(k) })),
  );

  const diagnosticProfile = (basics, { weak, strong }) => ({
    ...basics,
    onboarded: true,
    subjects_source: 'diagnostic',
    weak_subjects: weak,
    strong_subjects: strong,
  });

  it('is complete for any disjoint, duplicate-free, non-blank topic arrays', () => {
    fc.assert(
      fc.property(basicsArb, disjointTopicsArb, (basics, topics) => {
        expect(amIsProfileComplete(diagnosticProfile(basics, topics))).toBe(true);
      }),
      { numRuns: 100 },
    );
  });

  it('is incomplete when a topic appears in both arrays', () => {
    fc.assert(
      fc.property(basicsArb, disjointTopicsArb, topicArb, (basics, { weak, strong }, shared) => {
        const p = diagnosticProfile(basics, { weak: [...weak, shared], strong: [shared, ...strong] });
        expect(amIsProfileComplete(p)).toBe(false);
      }),
      { numRuns: 100 },
    );
  });
});
