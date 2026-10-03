// Scorer: per-topic counts and unrounded accuracy for one diagnostic attempt.
// Ported from the diagnostic-skillgps module (lib/dsScorer.js). Shared by client,
// API and tests.

/** Thrown when a topic has no answers to score. */
export class AmScoreError extends Error {
  constructor(message) {
    super(message);
    this.name = 'AmScoreError';
  }
}

/**
 * Score one topic's answers. Each answer is `{ is_correct }` or
 * `{ selected_answer, correct_answer }` (an explicit boolean `is_correct` wins).
 * Returns `{ total_questions, correct_answers, incorrect_answers, accuracy }` where
 * accuracy = correct_answers / total_questions. Throws AmScoreError for an empty set.
 * @param {Array<object>} answers
 */
export function amScoreTopic(answers) {
  if (!Array.isArray(answers) || answers.length === 0) {
    throw new AmScoreError('A topic must have at least one answer to score.');
  }
  let correct = 0;
  for (const a of answers) {
    const isCorrect =
      typeof a.is_correct === 'boolean'
        ? a.is_correct
        : a.selected_answer != null && a.correct_answer != null && a.selected_answer === a.correct_answer;
    if (isCorrect) correct += 1;
  }
  const total = answers.length;
  return {
    total_questions: total,
    correct_answers: correct,
    incorrect_answers: total - correct,
    accuracy: correct / total,
  };
}
