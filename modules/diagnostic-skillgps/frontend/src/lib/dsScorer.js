/**
 * Scorer — compares selected answers to correct answers for one topic and
 * computes per-topic counts and accuracy (unrounded).
 *
 * `scoreTopic(answers)` takes an array of per-question records, each with a
 * `selected_answer` (A-D) and `correct_answer` (A-D), and returns
 * `{ total_questions, correct_answers, incorrect_answers, accuracy }`.
 * Throws for an empty set. accuracy = correct_answers / total_questions.
 */

export class ScoreError extends Error {
  constructor(message) {
    super(message);
    this.name = 'ScoreError';
  }
}

export function scoreTopic(answers) {
  if (!Array.isArray(answers) || answers.length === 0) {
    throw new ScoreError('A topic must have at least one answer to score.');
  }
  let correct = 0;
  for (const a of answers) {
    const isCorrect =
      typeof a.is_correct === 'boolean'
        ? a.is_correct
        : a.selected_answer != null &&
          a.correct_answer != null &&
          a.selected_answer === a.correct_answer;
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

export default scoreTopic;
