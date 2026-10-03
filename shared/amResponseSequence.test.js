import { describe, it, expect } from 'vitest';
import { amBuildResponseSequence, AmSequenceError } from './amResponseSequence.js';

describe('amBuildResponseSequence', () => {
  it('builds an ordered sequence of is_correct flags', () => {
    const out = amBuildResponseSequence([{ is_correct: true, difficulty: 2 }, { isCorrect: false }]);
    expect(out).toEqual([{ is_correct: true, difficulty: 2 }, { is_correct: false }]);
  });

  it('orders by created_at when sequence_index is absent', () => {
    const out = amBuildResponseSequence([
      { is_correct: true, created_at: '2024-01-01T00:00:02Z' },
      { is_correct: false, created_at: '2024-01-01T00:00:01Z' },
    ]);
    expect(out.map((a) => a.is_correct)).toEqual([false, true]);
  });

  it('orders by sequence_index', () => {
    const out = amBuildResponseSequence([
      { is_correct: true, sequence_index: 1 },
      { is_correct: false, sequence_index: 0 },
    ]);
    expect(out.map((a) => a.is_correct)).toEqual([false, true]);
  });

  it('prefers sequence_index over a shared batch created_at', () => {
    const ts = '2024-01-01T00:00:00Z';
    const out = amBuildResponseSequence([
      { is_correct: true, sequence_index: 2, created_at: ts },
      { is_correct: false, sequence_index: 0, created_at: ts },
      { is_correct: true, sequence_index: 1, created_at: ts, difficulty: 3 },
    ]);
    expect(out).toEqual([{ is_correct: false }, { is_correct: true, difficulty: 3 }, { is_correct: true }]);
  });

  it('rejects an empty set', () => {
    expect(() => amBuildResponseSequence([])).toThrow(AmSequenceError);
  });

  it('rejects more than 20 answers', () => {
    const many = Array.from({ length: 21 }, () => ({ is_correct: true }));
    expect(() => amBuildResponseSequence(many)).toThrow(AmSequenceError);
  });

  it('reports a missing correctness value', () => {
    try {
      amBuildResponseSequence([{ difficulty: 2 }]);
      throw new Error('should have thrown');
    } catch (e) {
      expect(e).toBeInstanceOf(AmSequenceError);
      expect(e.fields.some((f) => f.includes('is_correct'))).toBe(true);
    }
  });

  it('reports an invalid difficulty', () => {
    try {
      amBuildResponseSequence([{ is_correct: true, difficulty: 5 }]);
      throw new Error('should have thrown');
    } catch (e) {
      expect(e).toBeInstanceOf(AmSequenceError);
      expect(e.fields.some((f) => f.includes('difficulty'))).toBe(true);
    }
  });
});
