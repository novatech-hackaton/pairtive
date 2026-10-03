import { describe, it, expect } from 'vitest';
import { buildResponseSequence, SequenceError } from './dsResponseSequence.js';

describe('buildResponseSequence', () => {
  it('builds an ordered sequence of is_correct flags', () => {
    const out = buildResponseSequence([
      { is_correct: true, difficulty: 2 },
      { isCorrect: false },
    ]);
    expect(out).toEqual([{ is_correct: true, difficulty: 2 }, { is_correct: false }]);
  });

  it('orders by created_at when present', () => {
    const out = buildResponseSequence([
      { is_correct: true, created_at: '2024-01-01T00:00:02Z' },
      { is_correct: false, created_at: '2024-01-01T00:00:01Z' },
    ]);
    expect(out.map((a) => a.is_correct)).toEqual([false, true]);
  });

  it('orders by sequence_index when created_at absent', () => {
    const out = buildResponseSequence([
      { is_correct: true, sequence_index: 1 },
      { is_correct: false, sequence_index: 0 },
    ]);
    expect(out.map((a) => a.is_correct)).toEqual([false, true]);
  });

  it('rejects an empty set', () => {
    expect(() => buildResponseSequence([])).toThrow(SequenceError);
  });

  it('rejects more than 20 answers', () => {
    const many = Array.from({ length: 21 }, () => ({ is_correct: true }));
    expect(() => buildResponseSequence(many)).toThrow(SequenceError);
  });

  it('reports a missing correctness value', () => {
    try {
      buildResponseSequence([{ difficulty: 2 }]);
      throw new Error('should have thrown');
    } catch (e) {
      expect(e).toBeInstanceOf(SequenceError);
      expect(e.fields.some((f) => f.includes('is_correct'))).toBe(true);
    }
  });

  it('reports an invalid difficulty', () => {
    try {
      buildResponseSequence([{ is_correct: true, difficulty: 5 }]);
      throw new Error('should have thrown');
    } catch (e) {
      expect(e.fields.some((f) => f.includes('difficulty'))).toBe(true);
    }
  });
});
