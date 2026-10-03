import { describe, it, expect } from 'vitest';
import { scoreTopic, ScoreError } from './dsScorer.js';

describe('scoreTopic', () => {
  it('counts correct and incorrect and computes accuracy', () => {
    const r = scoreTopic([
      { selected_answer: 'A', correct_answer: 'A' },
      { selected_answer: 'B', correct_answer: 'C' },
      { selected_answer: 'D', correct_answer: 'D' },
    ]);
    expect(r).toEqual({ total_questions: 3, correct_answers: 2, incorrect_answers: 1, accuracy: 2 / 3 });
  });

  it('honors an explicit is_correct flag', () => {
    const r = scoreTopic([{ is_correct: true }, { is_correct: false }]);
    expect(r.correct_answers).toBe(1);
    expect(r.incorrect_answers).toBe(1);
  });

  it('throws on an empty set', () => {
    expect(() => scoreTopic([])).toThrow(ScoreError);
  });

  it('keeps the invariant correct + incorrect === total', () => {
    const r = scoreTopic([
      { selected_answer: 'A', correct_answer: 'A' },
      { selected_answer: 'A', correct_answer: 'B' },
    ]);
    expect(r.correct_answers + r.incorrect_answers).toBe(r.total_questions);
  });
});
