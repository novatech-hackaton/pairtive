import { describe, expect, it } from 'vitest';
import {
  amIsProfileComplete,
  amSchoolKey,
  amToggleSubject,
  amValidateBasics,
  amValidateSubjects,
} from './amSubjects.js';

describe('amValidateSubjects', () => {
  it('accepts 1-3 weak and 1-3 strong with no overlap', () => {
    expect(amValidateSubjects(['Math'], ['English'])).toBeNull();
    expect(amValidateSubjects(['Math', 'Science', 'History'], ['English', 'Filipino', 'Programming'])).toBeNull();
  });
  it('rejects empty lists', () => {
    expect(amValidateSubjects([], ['English'])).toMatch(/want help/);
    expect(amValidateSubjects(['Math'], [])).toMatch(/can help/);
  });
  it('rejects more than 3', () => {
    expect(amValidateSubjects(['Math', 'Science', 'History', 'Filipino'], ['English'])).toMatch(/up to 3/);
  });
  it('rejects overlap', () => {
    expect(amValidateSubjects(['Math'], ['Math'])).toMatch(/both/);
  });
  it('rejects unknown and duplicate subjects', () => {
    expect(amValidateSubjects(['Art'], ['Math'])).toMatch(/Unknown/);
    expect(amValidateSubjects(['Math', 'Math'], ['English'])).toMatch(/once/);
  });
});

describe('amToggleSubject', () => {
  it('moves a subject out of the other list when picked', () => {
    const r = amToggleSubject(['Math'], ['English'], 'English');
    expect(r.list).toEqual(['Math', 'English']);
    expect(r.other).toEqual([]);
  });
  it('caps at 3', () => {
    const r = amToggleSubject(['Math', 'Science', 'History'], [], 'English');
    expect(r.error).toBeTruthy();
    expect(r.list).toHaveLength(3);
  });
  it('unselects', () => {
    expect(amToggleSubject(['Math'], [], 'Math').list).toEqual([]);
  });
});

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
    expect(amIsProfileComplete({ ...p, weak_subjects: [] })).toBe(false);
  });
  it('normalizes school names', () => {
    expect(amSchoolKey('  UP  Diliman! ')).toBe(amSchoolKey('up diliman'));
  });
});
