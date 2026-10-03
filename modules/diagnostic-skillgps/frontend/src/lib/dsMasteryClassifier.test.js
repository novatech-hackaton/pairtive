import { describe, it, expect, beforeEach, vi } from 'vitest';
import {
  classify,
  isClassificationError,
  __resetWarningLatchForTests,
} from './dsMasteryClassifier.js';

describe('Mastery_Classifier.classify', () => {
  beforeEach(() => __resetWarningLatchForTests());

  it('maps below 0.40 to Weak', () => {
    expect(classify(0)).toBe('Weak');
    expect(classify(0.39)).toBe('Weak');
  });

  it('maps [0.40, 0.70) to Developing', () => {
    expect(classify(0.4)).toBe('Developing');
    expect(classify(0.69)).toBe('Developing');
  });

  it('maps >= 0.70 to Proficient', () => {
    expect(classify(0.7)).toBe('Proficient');
    expect(classify(1)).toBe('Proficient');
  });

  it('returns a Classification_Error (not thrown) for non-finite input', () => {
    const r = classify(Number.NaN);
    expect(isClassificationError(r)).toBe(true);
    expect(classify(Infinity).error).toBe(true);
    expect(classify('x').error).toBe(true);
  });

  it('returns a Classification_Error for out-of-range input', () => {
    expect(classify(-0.1).error).toBe(true);
    expect(classify(1.1).error).toBe(true);
  });

  it('is monotonic: p1 <= p2 implies level(p1) <= level(p2)', () => {
    const order = { Weak: 0, Developing: 1, Proficient: 2 };
    const ps = [0, 0.1, 0.39, 0.4, 0.55, 0.69, 0.7, 0.9, 1];
    for (let i = 1; i < ps.length; i += 1) {
      expect(order[classify(ps[i])]).toBeGreaterThanOrEqual(order[classify(ps[i - 1])]);
    }
  });
});
